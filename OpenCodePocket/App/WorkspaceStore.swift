import Foundation
import Observation
import OpenCodeModels
import OpenCodeNetworking

@MainActor
@Observable
final class WorkspaceStore {
  var sessions: [Session] = []
  var selectedSessionID: String?
  var messagesBySession: [String: [MessageEnvelope]] = [:]
  var diffsBySession: [String: [FileDiff]] = [:]
  var sessionStatuses: [String: SessionStatus] = [:]
  var permissionsBySession: [String: [PermissionRequest]] = [:]
  var questionsBySession: [String: [QuestionRequest]] = [:]
  var todosBySession: [String: [TodoItem]] = [:]

  var availableAgents: [AgentDescriptor] = []
  var availableModels: [ModelOption] = []
  var selectedAgentName: String
  var selectedModel: ModelSelector?
  var selectedModelVariant: String?
  var showReasoningSummaries = true

  var draftMessage = ""
  var isSending = false
  var isCreatingSession = false
  var isRefreshingSessions = false
  var respondingPermissionRequestIDs: Set<String> = []
  var respondingQuestionRequestIDs: Set<String> = []

  private let connection: ConnectionStore
  private var eventsTask: Task<Void, Never>?
  private var sessionRefreshTasks: [String: Task<Void, Never>] = [:]
  private var sessionRefreshNeedsDiff: Set<String> = []

  init(connection: ConnectionStore) {
    self.connection = connection
    selectedAgentName = connection.initialSelectedAgentName
    selectedModel = connection.initialSelectedModel
    selectedModelVariant = connection.initialSelectedModelVariant
  }

  var selectedMessages: [MessageEnvelope] {
    guard let selectedSessionID else { return [] }
    return messagesBySession[selectedSessionID] ?? []
  }

  var selectedDiffs: [FileDiff] {
    guard let selectedSessionID else { return [] }
    return diffsBySession[selectedSessionID] ?? []
  }

  var selectedPermissions: [PermissionRequest] {
    guard let selectedSessionID else { return [] }
    return permissionsBySession[selectedSessionID] ?? []
  }

  var selectedQuestions: [QuestionRequest] {
    guard let selectedSessionID else { return [] }
    return questionsBySession[selectedSessionID] ?? []
  }

  var selectedTodos: [TodoItem] {
    guard let selectedSessionID else { return [] }
    return todosBySession[selectedSessionID] ?? []
  }

  var isRespondingToPermission: Bool {
    !respondingPermissionRequestIDs.isEmpty
  }

  var isRespondingToQuestion: Bool {
    !respondingQuestionRequestIDs.isEmpty
  }

  var visibleSessions: [Session] {
    sessions.filter { ($0.time.archived ?? 0) <= 0 }
  }

  var selectedModelDisplayName: String {
    guard
      let selectedModel,
      let match = availableModels.first(where: {
        $0.providerID == selectedModel.providerID && $0.modelID == selectedModel.modelID
      })
    else {
      return "Select model"
    }
    return match.modelName
  }

  var selectedModelVariants: [String] {
    guard
      let selectedModel,
      let match = availableModels.first(where: {
        $0.providerID == selectedModel.providerID && $0.modelID == selectedModel.modelID
      })
    else {
      return []
    }

    return match.variants
  }

  var selectedModelVariantDisplayName: String {
    guard let selectedModelVariant else {
      return "Default"
    }
    return selectedModelVariant.capitalized
  }

  var modelProviderGroups: [ModelProviderGroup] {
    let grouped = Dictionary(grouping: availableModels, by: \.providerID)
    return grouped.keys
      .sorted()
      .compactMap { providerID in
        guard let models = grouped[providerID], let first = models.first else {
          return nil
        }
        return ModelProviderGroup(
          providerID: providerID,
          providerName: first.providerName,
          models: models.sorted { lhs, rhs in
            lhs.modelName.localizedCaseInsensitiveCompare(rhs.modelName) == .orderedAscending
          }
        )
      }
  }

  func disconnect() {
    connection.disconnect()
  }

  func refreshSessions() async {
    if connection.isMockWorkspace {
      sessions.sort { $0.sortTimestamp > $1.sortTimestamp }
      if let selectedSessionID, visibleSessions.contains(where: { $0.id == selectedSessionID }) {
        return
      }
      selectedSessionID = visibleSessions.first?.id
      return
    }

    guard let client = connection.client else { return }
    guard !isRefreshingSessions else { return }

    isRefreshingSessions = true
    defer {
      isRefreshingSessions = false
    }

    do {
      var nextSessions = try await client.listSessions(directory: connection.resolvedDirectory)
      nextSessions.sort { $0.sortTimestamp > $1.sortTimestamp }

      sessions = nextSessions
      let validSessionIDs = Set(nextSessions.map(\.id))
      messagesBySession = messagesBySession.filter { validSessionIDs.contains($0.key) }
      diffsBySession = diffsBySession.filter { validSessionIDs.contains($0.key) }
      sessionStatuses = sessionStatuses.filter { validSessionIDs.contains($0.key) }
      permissionsBySession = permissionsBySession.filter { validSessionIDs.contains($0.key) }
      questionsBySession = questionsBySession.filter { validSessionIDs.contains($0.key) }
      todosBySession = todosBySession.filter { validSessionIDs.contains($0.key) }
      let nextVisible = visibleSessions

      if let selectedSessionID, nextVisible.contains(where: { $0.id == selectedSessionID }) {
        await loadMessages(sessionID: selectedSessionID)
        await loadDiffs(sessionID: selectedSessionID)
      } else {
        selectedSessionID = nextVisible.first?.id
        if let selectedSessionID {
          await loadMessages(sessionID: selectedSessionID)
          await loadDiffs(sessionID: selectedSessionID)
        }
      }

      await refreshPendingPrompts()
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func createSession(title: String? = nil) async {
    if connection.isMockWorkspace {
      let now = Date().timeIntervalSince1970 * 1000
      let created = Session(
        id: "ses_mock_\(UUID().uuidString.prefix(8))",
        slug: "mock-session",
        projectID: "prj_mock",
        directory: "/tmp/mock",
        parentID: nil,
        title: title?.trimmedNonEmpty ?? "New Session",
        version: "1",
        time: SessionTime(created: now, updated: now, archived: nil),
        summary: nil,
        share: nil,
        revert: nil
      )
      sessions.insert(created, at: 0)
      selectedSessionID = created.id
      messagesBySession[created.id] = []
      diffsBySession[created.id] = []
      sessionStatuses[created.id] = .idle
      return
    }

    guard let client = connection.client else { return }
    guard !isCreatingSession else { return }

    isCreatingSession = true
    defer {
      isCreatingSession = false
    }

    do {
      let created = try await client.createSession(
        SessionCreateRequest(title: title),
        directory: connection.resolvedDirectory
      )
      selectedSessionID = created.id
      await refreshSessions()
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func selectSession(_ sessionID: String?) async {
    guard let sessionID else { return }
    selectedSessionID = sessionID
    await loadMessages(sessionID: sessionID)
    await loadDiffs(sessionID: sessionID)
  }

  func loadMessages(sessionID: String, limit: Int? = nil) async {
    if connection.isMockWorkspace { return }
    guard let client = connection.client else { return }

    do {
      let messages = try await client.listMessages(
        sessionID: sessionID,
        limit: limit,
        directory: connection.resolvedDirectory
      )
      messagesBySession[sessionID] = messages
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func loadDiffs(sessionID: String) async {
    if connection.isMockWorkspace { return }
    guard let client = connection.client else { return }

    do {
      let diffs = try await client.getSessionDiff(sessionID: sessionID, directory: connection.resolvedDirectory)
      diffsBySession[sessionID] = diffs
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func sendDraftMessage(in sessionID: String) async {
    let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    if connection.isMockWorkspace {
      draftMessage = ""
      if let userMessage = makeMockMessage(sessionID: sessionID, role: .user, text: trimmed) {
        messagesBySession[sessionID, default: []].append(userMessage)
      }
      if let assistantMessage = makeMockMessage(sessionID: sessionID, role: .assistant, text: "Mock response for \"\(trimmed)\".") {
        messagesBySession[sessionID, default: []].append(assistantMessage)
      }
      return
    }

    guard let client = connection.client else { return }
    let original = trimmed
    draftMessage = ""
    isSending = true

    defer {
      isSending = false
    }

    do {
      let request = PromptRequest(
        model: selectedModel,
        agent: selectedAgentName.trimmedNonEmpty,
        variant: selectedModelVariant,
        parts: [.text(original)]
      )
      try await client.sendMessageAsync(sessionID: sessionID, body: request, directory: connection.resolvedDirectory)

      try? await Task.sleep(nanoseconds: 200_000_000)
      await loadMessages(sessionID: sessionID)
      await loadDiffs(sessionID: sessionID)
    } catch {
      connection.connectionError = error.localizedDescription
      draftMessage = original
    }
  }

  func abort(sessionID: String) async {
    if connection.isMockWorkspace {
      sessionStatuses[sessionID] = .idle
      return
    }

    guard let client = connection.client else { return }
    do {
      _ = try await client.abortSession(sessionID: sessionID, directory: connection.resolvedDirectory)
      sessionStatuses[sessionID] = .idle
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func sessionTitle(for sessionID: String) -> String {
    sessions.first(where: { $0.id == sessionID })?.title ?? "Session"
  }

  func statusLabel(for sessionID: String) -> String {
    sessionStatuses[sessionID]?.displayLabel ?? SessionStatus.idle.displayLabel
  }

  func status(for sessionID: String) -> SessionStatus {
    sessionStatuses[sessionID] ?? .idle
  }

  func isSessionRunning(_ sessionID: String) -> Bool {
    status(for: sessionID).isRunning
  }

  func refreshAgentAndModelOptions() async {
    guard let client = connection.client else { return }

    do {
      let allAgents = try await client.listAgents(directory: connection.resolvedDirectory)
      let primaryAgents = allAgents
        .filter { $0.mode == "primary" }
        .filter { $0.hidden != true }
        .sorted { lhs, rhs in
          lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

      availableAgents = primaryAgents

      if !availableAgents.contains(where: { $0.name == selectedAgentName }) {
        if let buildAgent = availableAgents.first(where: { $0.name == "build" }) {
          selectedAgentName = buildAgent.name
        } else {
          selectedAgentName = availableAgents.first?.name ?? selectedAgentName
        }
      }
    } catch {
      connection.connectionError = error.localizedDescription
    }

    do {
      let catalog = try await client.listConfigProviders(directory: connection.resolvedDirectory)
      var options: [ModelOption] = []

      for provider in catalog.providers {
        for model in provider.models.values {
          options.append(
            ModelOption(
              providerID: provider.id,
              providerName: provider.name,
              modelID: model.id,
              modelName: model.name,
              variants: model.variants?.keys.sorted() ?? []
            )
          )
        }
      }

      options.sort { lhs, rhs in
        if lhs.providerName != rhs.providerName {
          return lhs.providerName.localizedCaseInsensitiveCompare(rhs.providerName) == .orderedAscending
        }
        return lhs.modelName.localizedCaseInsensitiveCompare(rhs.modelName) == .orderedAscending
      }

      availableModels = options
      reconcileSelectedModel(using: catalog.defaultModels)
      reconcileSelectedModelVariant()
      connection.persistSettingsBestEffort(
        selectedAgentName: selectedAgentName,
        selectedModel: selectedModel,
        selectedModelVariant: selectedModelVariant
      )
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func selectAgent(named name: String) {
    selectedAgentName = name
    connection.persistSettingsBestEffort(
      selectedAgentName: selectedAgentName,
      selectedModel: selectedModel,
      selectedModelVariant: selectedModelVariant
    )
  }

  func selectModel(_ option: ModelOption) {
    selectedModel = option.selector
    reconcileSelectedModelVariant()
    connection.persistSettingsBestEffort(
      selectedAgentName: selectedAgentName,
      selectedModel: selectedModel,
      selectedModelVariant: selectedModelVariant
    )
  }

  func selectModelVariant(_ variant: String?) {
    selectedModelVariant = variant?.trimmedNonEmpty
    reconcileSelectedModelVariant()
    connection.persistSettingsBestEffort(
      selectedAgentName: selectedAgentName,
      selectedModel: selectedModel,
      selectedModelVariant: selectedModelVariant
    )
  }

  func currentPermissionRequest(for sessionID: String) -> PermissionRequest? {
    permissionsBySession[sessionID]?.first
  }

  func currentQuestionRequest(for sessionID: String) -> QuestionRequest? {
    questionsBySession[sessionID]?.first
  }

  func linkedToolPart(for sessionID: String, reference: PermissionToolReference?) -> MessagePart? {
    guard let reference else {
      return nil
    }

    guard let messages = messagesBySession[sessionID] else {
      return nil
    }

    if
      let message = messages.first(where: { $0.id == reference.messageID }),
      let part = message.parts.first(where: { $0.type == "tool" && $0.callID == reference.callID })
    {
      return part
    }

    return messages
      .flatMap(\.parts)
      .first(where: { $0.type == "tool" && $0.callID == reference.callID })
  }

  func isComposerBlocked(for sessionID: String) -> Bool {
    currentPermissionRequest(for: sessionID) != nil || currentQuestionRequest(for: sessionID) != nil
  }

  func isRespondingToPermission(requestID: String) -> Bool {
    respondingPermissionRequestIDs.contains(requestID)
  }

  func isRespondingToQuestion(requestID: String) -> Bool {
    respondingQuestionRequestIDs.contains(requestID)
  }

  func refreshPendingPrompts() async {
    if connection.isMockWorkspace {
      return
    }

    guard let client = connection.client else { return }

    do {
      let permissions = try await client.listPermissions(directory: connection.resolvedDirectory)
      permissionsBySession = Dictionary(grouping: permissions, by: \.sessionID)
    } catch {
      connection.connectionError = error.localizedDescription
    }

    do {
      let questions = try await client.listQuestions(directory: connection.resolvedDirectory)
      questionsBySession = Dictionary(grouping: questions, by: \.sessionID)
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func respondToPermission(sessionID: String, requestID: String, reply: PermissionReply, message: String? = nil) async {
    if connection.isMockWorkspace {
      permissionsBySession[sessionID]?.removeAll { $0.id == requestID }
      return
    }

    guard let client = connection.client else { return }
    guard !isRespondingToPermission(requestID: requestID) else { return }

    respondingPermissionRequestIDs.insert(requestID)
    defer {
      respondingPermissionRequestIDs.remove(requestID)
    }

    do {
      _ = try await client.replyPermission(
        requestID: requestID,
        reply: reply,
        message: message,
        directory: connection.resolvedDirectory
      )
      permissionsBySession[sessionID]?.removeAll { $0.id == requestID }
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func replyToQuestion(sessionID: String, requestID: String, answers: [QuestionAnswer]) async {
    if connection.isMockWorkspace {
      questionsBySession[sessionID]?.removeAll { $0.id == requestID }
      return
    }

    guard let client = connection.client else { return }
    guard !isRespondingToQuestion(requestID: requestID) else { return }

    respondingQuestionRequestIDs.insert(requestID)
    defer {
      respondingQuestionRequestIDs.remove(requestID)
    }

    do {
      _ = try await client.replyQuestion(
        requestID: requestID,
        answers: answers,
        directory: connection.resolvedDirectory
      )
      questionsBySession[sessionID]?.removeAll { $0.id == requestID }
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func rejectQuestion(sessionID: String, requestID: String) async {
    if connection.isMockWorkspace {
      questionsBySession[sessionID]?.removeAll { $0.id == requestID }
      return
    }

    guard let client = connection.client else { return }
    guard !isRespondingToQuestion(requestID: requestID) else { return }

    respondingQuestionRequestIDs.insert(requestID)
    defer {
      respondingQuestionRequestIDs.remove(requestID)
    }

    do {
      _ = try await client.rejectQuestion(requestID: requestID, directory: connection.resolvedDirectory)
      questionsBySession[sessionID]?.removeAll { $0.id == requestID }
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func renameSession(sessionID: String, title: String) async {
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedTitle.isEmpty else { return }

    if connection.isMockWorkspace {
      if let index = sessions.firstIndex(where: { $0.id == sessionID }) {
        var updated = sessions[index]
        updated = Session(
          id: updated.id,
          slug: updated.slug,
          projectID: updated.projectID,
          directory: updated.directory,
          parentID: updated.parentID,
          title: trimmedTitle,
          version: updated.version,
          time: updated.time,
          summary: updated.summary,
          share: updated.share,
          revert: updated.revert
        )
        sessions[index] = updated
      }
      return
    }

    guard let client = connection.client else { return }
    do {
      _ = try await client.updateSession(
        id: sessionID,
        body: SessionUpdateRequest(title: trimmedTitle),
        directory: connection.resolvedDirectory
      )
      await refreshSessions()
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func archiveSession(sessionID: String) async {
    let archiveTime = Date().timeIntervalSince1970 * 1000

    if connection.isMockWorkspace {
      if let index = sessions.firstIndex(where: { $0.id == sessionID }) {
        var updated = sessions[index]
        updated = Session(
          id: updated.id,
          slug: updated.slug,
          projectID: updated.projectID,
          directory: updated.directory,
          parentID: updated.parentID,
          title: updated.title,
          version: updated.version,
          time: SessionTime(created: updated.time.created, updated: updated.time.updated, archived: archiveTime),
          summary: updated.summary,
          share: updated.share,
          revert: updated.revert
        )
        sessions[index] = updated
        if selectedSessionID == sessionID {
          selectedSessionID = visibleSessions.first?.id
        }
      }
      return
    }

    guard let client = connection.client else { return }
    do {
      _ = try await client.updateSession(
        id: sessionID,
        body: SessionUpdateRequest(time: SessionUpdateTime(archived: archiveTime)),
        directory: connection.resolvedDirectory
      )
      await refreshSessions()
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func deleteSession(sessionID: String) async {
    if connection.isMockWorkspace {
      sessions.removeAll { $0.id == sessionID }
      messagesBySession[sessionID] = nil
      diffsBySession[sessionID] = nil
      sessionStatuses[sessionID] = nil
      permissionsBySession[sessionID] = nil
      questionsBySession[sessionID] = nil
      todosBySession[sessionID] = nil
      if selectedSessionID == sessionID {
        selectedSessionID = visibleSessions.first?.id
      }
      return
    }

    guard let client = connection.client else { return }
    do {
      _ = try await client.deleteSession(id: sessionID, directory: connection.resolvedDirectory)
      messagesBySession[sessionID] = nil
      diffsBySession[sessionID] = nil
      sessionStatuses[sessionID] = nil
      permissionsBySession[sessionID] = nil
      questionsBySession[sessionID] = nil
      todosBySession[sessionID] = nil
      await refreshSessions()
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

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
      if let errorObject = properties.object(for: "error") {
        connection.connectionError = JSONValue.object(errorObject).compactDescription
      }

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

  private func reconcileSelectedModel(using defaultModels: [String: String]) {
    if
      let selectedModel,
      availableModels.contains(where: {
        $0.providerID == selectedModel.providerID && $0.modelID == selectedModel.modelID
      })
    {
      return
    }

    for (providerID, modelID) in defaultModels {
      if let match = availableModels.first(where: { $0.providerID == providerID && $0.modelID == modelID }) {
        selectedModel = match.selector
        return
      }
    }

    selectedModel = availableModels.first?.selector
  }

  private func reconcileSelectedModelVariant() {
    guard let selectedModelVariant else {
      return
    }

    guard selectedModelVariants.contains(selectedModelVariant) else {
      self.selectedModelVariant = nil
      return
    }
  }

  func seedMockWorkspace() {
    let now = Date().timeIntervalSince1970 * 1000

    let primary = Session(
      id: "ses_mock_primary",
      slug: "mock-primary",
      projectID: "prj_mock",
      directory: "/tmp/opencode-pocket",
      parentID: nil,
      title: "Mock Workspace Session",
      version: "1",
      time: SessionTime(created: now - 50000, updated: now - 5000, archived: nil),
      summary: nil,
      share: nil,
      revert: nil
    )

    let secondary = Session(
      id: "ses_mock_secondary",
      slug: "mock-secondary",
      projectID: "prj_mock",
      directory: "/tmp/opencode-pocket",
      parentID: nil,
      title: "Mock Planning Session",
      version: "1",
      time: SessionTime(created: now - 140_000, updated: now - 40000, archived: nil),
      summary: nil,
      share: nil,
      revert: nil
    )

    sessions = [primary, secondary]
    selectedSessionID = primary.id
    sessionStatuses[primary.id] = .idle
    sessionStatuses[secondary.id] = .idle
    diffsBySession[primary.id] = [
      FileDiff(file: "OpenCodePocket/App/AppStore.swift", before: "", after: "", additions: 24, deletions: 9, status: "modified"),
      FileDiff(file: "OpenCodePocket/Features/WorkspaceView.swift", before: "", after: "", additions: 108, deletions: 0, status: "added"),
    ]
    diffsBySession[secondary.id] = []
    availableAgents = [
      AgentDescriptor(name: "build", description: "Executes tools based on configured permissions.", mode: "primary", hidden: false),
      AgentDescriptor(name: "plan", description: "Planning mode with edit restrictions.", mode: "primary", hidden: false),
    ]
    availableModels = [
      ModelOption(providerID: "openai", providerName: "OpenAI", modelID: "gpt-5.3-codex", modelName: "GPT-5.3 Codex", variants: ["low", "medium", "high"]),
      ModelOption(providerID: "anthropic", providerName: "Anthropic", modelID: "claude-sonnet-4-5", modelName: "Claude Sonnet 4.5", variants: ["high", "max"]),
    ]

    if !availableAgents.contains(where: { $0.name == selectedAgentName }) {
      selectedAgentName = "build"
    }
    selectedModel = availableModels.first?.selector
    reconcileSelectedModelVariant()

    if let greeting = makeMockMessage(sessionID: primary.id, role: .assistant, text: "Welcome to the mock workspace.") {
      messagesBySession[primary.id] = [greeting]
    }

    connection.isConnected = true
    connection.eventConnectionState = "Mock workspace"
    connection.serverVersion = "mock"
    connection.connectionError = nil
  }

  private func makeMockMessage(sessionID: String, role: MessageRole, text: String) -> MessageEnvelope? {
    let messageID = "msg_mock_\(UUID().uuidString.prefix(10))"

    let payload: [String: Any] = [
      "info": [
        "id": messageID,
        "sessionID": sessionID,
        "role": role.rawValue,
        "agent": selectedAgentName,
      ],
      "parts": [
        [
          "id": "prt_mock_\(UUID().uuidString.prefix(10))",
          "sessionID": sessionID,
          "messageID": messageID,
          "type": "text",
          "text": text,
        ],
      ],
    ]

    guard
      let data = try? JSONSerialization.data(withJSONObject: payload),
      let envelope = try? JSONDecoder().decode(MessageEnvelope.self, from: data)
    else {
      return nil
    }

    return envelope
  }
}
