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
    switch event.type {
    case "server.connected":
      connection.eventConnectionState = "Live updates connected"

    case "session.created", "session.updated", "session.deleted":
      await refreshSessions()

    case "session.idle":
      if let sessionID = event.properties.objectValue?.string(for: "sessionID") {
        sessionStatuses[sessionID] = .idle
        scheduleSessionRefresh(sessionID: sessionID)
        notifyAgentIfEnabled(sessionID: sessionID, reason: "complete")
      }

    case "session.status":
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

    case "session.error":
      guard let properties = event.properties.objectValue else { return }
      if let sessionID = properties.string(for: "sessionID") {
        sessionStatuses[sessionID] = .idle
      }
      var errorDescription: String?
      if let errorObject = properties.object(for: "error") {
        let compact = JSONValue.object(errorObject).compactDescription
        connection.connectionError = compact
        errorDescription = compact
      }
      notifyErrorIfEnabled(sessionID: properties.string(for: "sessionID"), errorDescription: errorDescription)

    case "session.diff":
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

    case "todo.updated":
      guard
        let properties = event.properties.objectValue,
        let sessionID = properties.string(for: "sessionID")
      else {
        return
      }

      if let decoded = properties["todos"]?.decoded(as: [TodoItem].self) {
        todosBySession[sessionID] = decoded
      }

    case "permission.asked":
      guard let permission = event.decodeProperties(as: PermissionRequest.self) else {
        return
      }
      upsertPermission(permission)
      notifyPermissionIfEnabled(permission)

    case "permission.replied":
      guard
        let properties = event.properties.objectValue,
        let sessionID = properties.string(for: "sessionID"),
        let requestID = properties.string(for: "requestID")
      else {
        return
      }
      permissionsBySession[sessionID]?.removeAll { $0.id == requestID }

    case "question.asked":
      guard let question = event.decodeProperties(as: QuestionRequest.self) else {
        return
      }
      upsertQuestion(question)
      notifyAgentIfEnabled(sessionID: question.sessionID, reason: "question")

    case "question.replied", "question.rejected":
      guard
        let properties = event.properties.objectValue,
        let sessionID = properties.string(for: "sessionID"),
        let requestID = properties.string(for: "requestID")
      else {
        return
      }
      questionsBySession[sessionID]?.removeAll { $0.id == requestID }

    case "message.part.delta":
      guard
        let properties = event.properties.objectValue,
        let sessionID = properties.string(for: "sessionID")
      else {
        return
      }

      if applyMessagePartDelta(properties: properties) {
        scheduleSessionRefresh(sessionID: sessionID, includeDiffs: false)
      } else {
        scheduleSessionRefresh(sessionID: sessionID)
      }

    case "message.part.updated":
      guard let properties = event.properties.objectValue else {
        return
      }

      if applyMessagePartUpdated(properties: properties) {
        scheduleSessionRefresh(sessionID: properties.object(for: "part")?.string(for: "sessionID"), includeDiffs: false)
      } else {
        scheduleSessionRefresh(sessionID: properties.object(for: "part")?.string(for: "sessionID"))
      }

    case "message.part.removed":
      guard let properties = event.properties.objectValue else {
        return
      }

      if applyMessagePartRemoval(properties: properties) {
        scheduleSessionRefresh(sessionID: properties.string(for: "sessionID"), includeDiffs: false)
      } else {
        scheduleSessionRefresh(sessionID: properties.string(for: "sessionID"))
      }

    case "message.updated", "message.removed":
      guard let properties = event.properties.objectValue else {
        let sessionID = selectedSessionID
        scheduleSessionRefresh(sessionID: sessionID)
        return
      }

      if event.type == "message.updated" {
        if applyMessageUpdated(properties: properties) {
          return
        }
        let sessionID =
          properties.object(for: "info")?.string(for: "sessionID")
            ?? properties.string(for: "sessionID")
            ?? selectedSessionID
        scheduleSessionRefresh(sessionID: sessionID, includeDiffs: false)
        return
      }

      if applyMessageRemoval(properties: properties) {
        return
      }
      let sessionID = properties.string(for: "sessionID") ?? selectedSessionID
      scheduleSessionRefresh(sessionID: sessionID, includeDiffs: false)

    default:
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

  private func applyMessagePartDelta(properties: [String: JSONValue]) -> Bool {
    guard
      let sessionID = properties.string(for: "sessionID"),
      let messageID = properties.string(for: "messageID"),
      let partID = properties.string(for: "partID"),
      let field = properties.string(for: "field"),
      let delta = properties.string(for: "delta"),
      !delta.isEmpty,
      var messages = messagesBySession[sessionID],
      let messageIndex = messages.firstIndex(where: { $0.info.id == messageID }),
      let partIndex = messages[messageIndex].parts.firstIndex(where: { $0.id == partID }),
      let updatedPart = messages[messageIndex].parts[partIndex].appendingDelta(field: field, delta: delta)
    else {
      return false
    }

    var updatedParts = messages[messageIndex].parts
    updatedParts[partIndex] = updatedPart
    messages[messageIndex] = MessageEnvelope(info: messages[messageIndex].info, parts: updatedParts)
    messagesBySession[sessionID] = messages
    return true
  }

  private func applyMessagePartUpdated(properties: [String: JSONValue]) -> Bool {
    guard
      let partValue = properties["part"],
      let part = partValue.decoded(as: MessagePart.self),
      var messages = messagesBySession[part.sessionID],
      let messageIndex = messages.firstIndex(where: { $0.info.id == part.messageID })
    else {
      return false
    }

    var updatedParts = messages[messageIndex].parts
    if let partIndex = updatedParts.firstIndex(where: { $0.id == part.id }) {
      updatedParts[partIndex] = part
    } else {
      let insertIndex = updatedParts.firstIndex(where: { $0.id > part.id }) ?? updatedParts.count
      updatedParts.insert(part, at: insertIndex)
    }

    messages[messageIndex] = MessageEnvelope(info: messages[messageIndex].info, parts: updatedParts)
    messagesBySession[part.sessionID] = messages
    return true
  }

  private func applyMessageUpdated(properties: [String: JSONValue]) -> Bool {
    let info: MessageInfo?
    if let infoValue = properties["info"] {
      info = infoValue.decoded(as: MessageInfo.self)
    } else {
      info = JSONValue.object(properties).decoded(as: MessageInfo.self)
    }

    guard let info else {
      return false
    }

    var messages = messagesBySession[info.sessionID] ?? []
    if let index = messages.firstIndex(where: { $0.info.id == info.id }) {
      let existingParts = messages[index].parts
      messages[index] = MessageEnvelope(info: info, parts: existingParts)
    } else {
      let insertIndex = messages.firstIndex(where: { $0.info.id > info.id }) ?? messages.count
      messages.insert(MessageEnvelope(info: info, parts: []), at: insertIndex)
    }

    messagesBySession[info.sessionID] = messages
    return true
  }

  private func applyMessageRemoval(properties: [String: JSONValue]) -> Bool {
    guard
      let sessionID = properties.string(for: "sessionID"),
      let messageID = properties.string(for: "messageID"),
      var messages = messagesBySession[sessionID]
    else {
      return false
    }

    let originalCount = messages.count
    messages.removeAll { $0.info.id == messageID }
    guard messages.count != originalCount else {
      return false
    }

    messagesBySession[sessionID] = messages
    return true
  }

  private func applyMessagePartRemoval(properties: [String: JSONValue]) -> Bool {
    guard
      let sessionID = properties.string(for: "sessionID"),
      let messageID = properties.string(for: "messageID"),
      let partID = properties.string(for: "partID"),
      var messages = messagesBySession[sessionID],
      let messageIndex = messages.firstIndex(where: { $0.info.id == messageID })
    else {
      return false
    }

    var updatedParts = messages[messageIndex].parts
    let originalCount = updatedParts.count
    updatedParts.removeAll { $0.id == partID }
    guard updatedParts.count != originalCount else {
      return false
    }

    messages[messageIndex] = MessageEnvelope(info: messages[messageIndex].info, parts: updatedParts)
    messagesBySession[sessionID] = messages
    return true
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
