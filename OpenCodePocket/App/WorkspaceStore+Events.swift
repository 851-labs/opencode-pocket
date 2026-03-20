import Foundation
import OpenCodeModels

#if os(macOS)
  import AppKit
  import UserNotifications
#endif

@MainActor
extension WorkspaceStore {
  func startEventSubscriptionLoop() {
    stopEventSubscriptionLoop()
    clearSessionRefreshState()
    guard let client = connection.client else { return }

    eventsTask = Task { [weak self] in
      guard let self else { return }
      await self.refreshPendingPrompts()
      let stream = client.subscribeEvents(directory: self.connection.resolvedDirectory)

      for await event in stream {
        await self.handle(event: event)
      }
    }
  }

  func stopEventSubscriptionLoop() {
    eventsTask?.cancel()
    eventsTask = nil
  }

  func clearSessionRefreshState() {
    sessionRefreshTasks.values.forEach { $0.cancel() }
    sessionRefreshTasks.removeAll()
    sessionRefreshNeedsDiff.removeAll()
  }

  private func handle(event: ServerEvent) async {
    switch event.eventType {
    case .serverConnected:
      connection.eventConnectionState = "Live updates connected"

    case .serverHeartbeat, .globalDisposed, .projectUpdated, .fileWatcherUpdated, .serverInstanceDisposed, .vcsBranchUpdated:
      break

    case .sessionCreated, .sessionUpdated, .sessionDeleted:
      await refreshSessions()

    case .sessionIdle:
      if let sessionID = event.properties.objectValue?.string(for: "sessionID") {
        sessionStatuses[sessionID] = .idle
        scheduleSessionRefresh(sessionID: sessionID)
        notifyAgentIfEnabled(sessionID: sessionID, reason: "complete")
      }

    case .sessionStatus:
      guard
        let properties = event.properties.objectValue,
        let sessionID = properties.string(for: "sessionID")
      else {
        return
      }

      if
        let statusValue = properties["status"],
        let decodedStatus = statusValue.decoded(as: SessionStatus.self)
      {
        sessionStatuses[sessionID] = decodedStatus
      } else {
        sessionStatuses[sessionID] = SessionStatus(type: .unknown("unknown"))
      }

    case .sessionError:
      guard let properties = event.properties.objectValue else { return }
      if let sessionID = properties.string(for: "sessionID") {
        sessionStatuses[sessionID] = .idle
      }
      var errorDescription: String?
      if let errorObject = properties.object(for: "error") {
        let compact = JSONValue.object(errorObject).compactDescription
        workspaceError = compact
        errorDescription = compact
      }
      notifyErrorIfEnabled(sessionID: properties.string(for: "sessionID"), errorDescription: errorDescription)

    case .sessionDiff:
      guard
        let properties = event.properties.objectValue,
        let sessionID = properties.string(for: "sessionID")
      else {
        return
      }

      if let decoded = properties["diff"]?.decoded(as: [FileDiff].self) {
        diffsBySession[sessionID] = decoded
      } else {
        scheduleSessionRefresh(sessionID: sessionID)
      }

    case .todoUpdated:
      guard
        let properties = event.properties.objectValue,
        let sessionID = properties.string(for: "sessionID")
      else {
        return
      }

      if let decoded = properties["todos"]?.decoded(as: [TodoItem].self) {
        todosBySession[sessionID] = decoded
      }

    case .permissionAsked:
      guard let permission = event.decodeProperties(as: PermissionRequest.self) else {
        return
      }
      upsertPermission(permission)
      notifyPermissionIfEnabled(permission)

    case .permissionReplied:
      guard
        let properties = event.properties.objectValue,
        let sessionID = properties.string(for: "sessionID"),
        let requestID = properties.string(for: "requestID")
      else {
        return
      }
      permissionsBySession[sessionID]?.removeAll { $0.id == requestID }

    case .questionAsked:
      guard let question = event.decodeProperties(as: QuestionRequest.self) else {
        return
      }
      upsertQuestion(question)
      notifyAgentIfEnabled(sessionID: question.sessionID, reason: "question")

    case .questionReplied, .questionRejected:
      guard
        let properties = event.properties.objectValue,
        let sessionID = properties.string(for: "sessionID"),
        let requestID = properties.string(for: "requestID")
      else {
        return
      }
      questionsBySession[sessionID]?.removeAll { $0.id == requestID }

    case .messagePartDelta:
      guard
        let properties = event.properties.objectValue,
        let sessionID = properties.string(for: "sessionID")
      else {
        return
      }

      if applyMessageMutation(properties: properties, using: MessageEnvelope.partDeltaMutation) != nil {
        scheduleSessionRefresh(sessionID: sessionID, includeDiffs: false)
      } else {
        scheduleSessionRefresh(sessionID: sessionID)
      }

    case .messagePartUpdated:
      guard let properties = event.properties.objectValue else {
        return
      }

      if let sessionID = applyMessageMutation(properties: properties, using: MessageEnvelope.partUpdatedMutation) {
        scheduleSessionRefresh(sessionID: sessionID, includeDiffs: false)
      } else {
        scheduleSessionRefresh(sessionID: properties.object(for: "part")?.string(for: "sessionID"))
      }

    case .messagePartRemoved:
      guard let properties = event.properties.objectValue else {
        return
      }

      if let sessionID = applyMessageMutation(properties: properties, using: MessageEnvelope.partRemovalMutation) {
        scheduleSessionRefresh(sessionID: sessionID, includeDiffs: false)
      } else {
        scheduleSessionRefresh(sessionID: properties.string(for: "sessionID"))
      }

    case .messageUpdated:
      guard let properties = event.properties.objectValue else {
        let sessionID = selectedSessionID
        scheduleSessionRefresh(sessionID: sessionID)
        return
      }

      if applyMessageMutation(properties: properties, using: MessageEnvelope.messageUpdatedMutation) != nil {
        return
      }
      let sessionID =
        properties.object(for: "info")?.string(for: "sessionID")
          ?? properties.string(for: "sessionID")
          ?? selectedSessionID
      scheduleSessionRefresh(sessionID: sessionID, includeDiffs: false)

    case .messageRemoved:
      guard let properties = event.properties.objectValue else {
        let sessionID = selectedSessionID
        scheduleSessionRefresh(sessionID: sessionID, includeDiffs: false)
        return
      }

      if applyMessageMutation(properties: properties, using: MessageEnvelope.messageRemovalMutation) != nil {
        return
      }
      let sessionID = properties.string(for: "sessionID") ?? selectedSessionID
      scheduleSessionRefresh(sessionID: sessionID, includeDiffs: false)

    case .lspUpdated:
      await refreshLSPStatuses()

    case .mcpToolsChanged:
      await refreshMCPStatuses()

    case .unknown:
      break
    }
  }

  private func scheduleSessionRefresh(sessionID: String?, includeDiffs: Bool = true) {
    guard let sessionID else { return }

    if includeDiffs {
      sessionRefreshNeedsDiff.insert(sessionID)
    }

    if sessionRefreshTasks[sessionID] != nil {
      return
    }

    sessionRefreshTasks[sessionID] = Task { [weak self] in
      try? await Task.sleep(nanoseconds: 300_000_000)
      await self?.runScheduledSessionRefresh(sessionID: sessionID)
    }
  }

  private func runScheduledSessionRefresh(sessionID: String) async {
    defer {
      sessionRefreshTasks[sessionID] = nil
    }

    await loadMessages(sessionID: sessionID)

    let shouldRefreshDiffs = sessionRefreshNeedsDiff.remove(sessionID) != nil
    if shouldRefreshDiffs {
      await loadDiffs(sessionID: sessionID)
    }
  }

  private func applyMessageMutation(
    properties: [String: JSONValue],
    using mutation: ([String: JSONValue], [String: [MessageEnvelope]]) -> (sessionID: String, messages: [MessageEnvelope])?
  ) -> String? {
    guard let update = mutation(properties, messagesBySession) else {
      return nil
    }

    var messages = messagesBySession
    messages[update.sessionID] = update.messages
    messagesBySession = messages
    return update.sessionID
  }

  private func upsertPermission(_ permission: PermissionRequest) {
    var next = permissionsBySession[permission.sessionID] ?? []
    if let index = next.firstIndex(where: { $0.id == permission.id }) {
      next[index] = permission
    } else {
      next.append(permission)
    }
    permissionsBySession[permission.sessionID] = next.sorted { $0.id < $1.id }
  }

  private func upsertQuestion(_ question: QuestionRequest) {
    var next = questionsBySession[question.sessionID] ?? []
    if let index = next.firstIndex(where: { $0.id == question.id }) {
      next[index] = question
    } else {
      next.append(question)
    }
    questionsBySession[question.sessionID] = next.sorted { $0.id < $1.id }
  }

  private func shouldNotifyForSession(_ sessionID: String?) -> Bool {
    guard let sessionID else {
      return true
    }

    guard let session = sessions.first(where: { $0.id == sessionID }) else {
      return true
    }

    return session.parentID == nil
  }

  private func notifyAgentIfEnabled(sessionID: String, reason: String) {
    guard notifyAgentSystemNotifications else {
      return
    }

    guard shouldNotifyForSession(sessionID) else {
      return
    }

    let title = reason == "question" ? "Agent needs attention" : "Response ready"
    let body = sessionTitle(for: sessionID)

    #if os(macOS)
      MacSystemNotificationService.shared.post(title: title, body: body, threadIdentifier: sessionID)
    #endif
  }

  private func notifyPermissionIfEnabled(_ permission: PermissionRequest) {
    guard notifyPermissionSystemNotifications else {
      return
    }

    guard shouldNotifyForSession(permission.sessionID) else {
      return
    }

    let body = sessionTitle(for: permission.sessionID)

    #if os(macOS)
      MacSystemNotificationService.shared.post(title: "Permission required", body: body, threadIdentifier: permission.sessionID)
    #endif
  }

  private func notifyErrorIfEnabled(sessionID: String?, errorDescription: String?) {
    guard notifyErrorSystemNotifications else {
      return
    }

    guard shouldNotifyForSession(sessionID) else {
      return
    }

    let body = sessionID.map { sessionTitle(for: $0) } ?? errorDescription ?? "An error occurred"

    #if os(macOS)
      MacSystemNotificationService.shared.post(title: "Session error", body: body, threadIdentifier: sessionID)
    #endif
  }
}

#if os(macOS)
  @MainActor
  private final class MacSystemNotificationService {
    static let shared = MacSystemNotificationService()

    private let center: UNUserNotificationCenter
    private var didRequestAuthorization = false

    init(center: UNUserNotificationCenter = .current()) {
      self.center = center
    }

    func post(title: String, body: String, threadIdentifier: String?) {
      guard !NSApplication.shared.isActive else {
        return
      }

      ensureAuthorizationRequested()

      Task {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
          return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let threadIdentifier {
          content.threadIdentifier = threadIdentifier
        }

        let request = UNNotificationRequest(
          identifier: UUID().uuidString,
          content: content,
          trigger: nil
        )

        try? await center.add(request)
      }
    }

    private func ensureAuthorizationRequested() {
      guard !didRequestAuthorization else {
        return
      }

      didRequestAuthorization = true

      Task {
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
      }
    }
  }
#endif
