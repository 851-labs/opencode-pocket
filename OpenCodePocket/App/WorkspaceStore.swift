import Foundation
import Observation
import OpenCodeModels
import OpenCodeNetworking

@MainActor
@Observable
final class WorkspaceStore {
  var projects: [SavedProject] = []
  var selectedProjectID: String?

  var sessions: [Session] = []
  var pinnedSessionIDs: Set<String> = []
  var selectedSessionID: String?
  var messagesBySession: [String: [MessageEnvelope]] = [:]
  var messageLoadCountsBySession: [String: Int] = [:]
  var diffsBySession: [String: [FileDiff]] = [:]
  var sessionStatuses: [String: SessionStatus] = [:]
  var permissionsBySession: [String: [PermissionRequest]] = [:]
  var questionsBySession: [String: [QuestionRequest]] = [:]
  var todosBySession: [String: [TodoItem]] = [:]

  var availableAgents: [AgentDescriptor] = []
  var availableModels: [ModelOption] = []
  var hiddenModelKeys: Set<String>
  var selectedAgentName: String
  var selectedModel: ModelSelector?
  var selectedModelVariant: String?
  var showReasoningSummaries = false {
    didSet {
      guard oldValue != showReasoningSummaries else { return }
      persistWorkspaceSettings()
    }
  }

  var expandShellToolParts = true {
    didSet {
      guard oldValue != expandShellToolParts else { return }
      persistWorkspaceSettings()
    }
  }

  var expandEditToolParts = false {
    didSet {
      guard oldValue != expandEditToolParts else { return }
      persistWorkspaceSettings()
    }
  }

  var draftMessage = ""
  var isSending = false
  var isCreatingSession = false
  var isRefreshingSessions = false
  var respondingPermissionRequestIDs: Set<String> = []
  var respondingQuestionRequestIDs: Set<String> = []

  let connection: ConnectionStore
  var eventsTask: Task<Void, Never>?
  var sessionRefreshTasks: [String: Task<Void, Never>] = [:]
  var sessionRefreshNeedsDiff: Set<String> = []
  let allowsPersistence: Bool

  init(connection: ConnectionStore, allowsPersistence: Bool = true) {
    self.connection = connection
    self.allowsPersistence = allowsPersistence
    hiddenModelKeys = connection.initialHiddenModelKeys
    selectedAgentName = connection.initialSelectedAgentName
    selectedModel = connection.initialSelectedModel
    selectedModelVariant = connection.initialSelectedModelVariant
    showReasoningSummaries = connection.initialShowReasoningSummaries
    expandShellToolParts = connection.initialExpandShellToolParts
    expandEditToolParts = connection.initialExpandEditToolParts
    pinnedSessionIDs = connection.initialPinnedSessionIDs

    if connection.initialProjects.isEmpty {
      let defaultDirectory = connection.directory.trimmedNonEmpty ?? NSHomeDirectory()
      let project = Self.makeProject(directory: defaultDirectory)
      projects = [project]
      selectedProjectID = project.id
    } else {
      projects = connection.initialProjects
      let preferredID = connection.initialSelectedProjectID
      selectedProjectID = projects.contains(where: { $0.id == preferredID }) ? preferredID : projects.first?.id
    }

    if let selectedProjectID, let selectedProject = projects.first(where: { $0.id == selectedProjectID }) {
      connection.directory = selectedProject.directory
    }
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

  var latestConnectionError: String? {
    connection.connectionError
  }

  func clearConnectionError() {
    connection.connectionError = nil
  }

  var activeProject: SavedProject? {
    guard let selectedProjectID else {
      return projects.first
    }
    return projects.first(where: { $0.id == selectedProjectID })
  }

  var activeProjectDirectory: String? {
    activeProject?.directory.trimmedNonEmpty
  }

  var visibleSessions: [Session] {
    guard let selectedProjectID else {
      return []
    }
    return visibleSessions(for: selectedProjectID)
  }

  var archivedSessions: [Session] {
    sessions
      .filter { ($0.time.archived ?? 0) > 0 }
      .sorted { lhs, rhs in
        let lhsArchived = lhs.time.archived ?? lhs.sortTimestamp
        let rhsArchived = rhs.time.archived ?? rhs.sortTimestamp
        return lhsArchived > rhsArchived
      }
  }

  var pinnedSessions: [Session] {
    sessions
      .filter { pinnedSessionIDs.contains($0.id) }
      .filter(isVisibleRootSession(_:))
      .sorted(by: isSessionNewer(_:than:))
  }

  func visibleSessions(for projectID: String) -> [Session] {
    guard let project = projects.first(where: { $0.id == projectID }) else {
      return []
    }

    return sessions
      .filter { $0.directory == project.directory }
      .filter(isVisibleRootSession(_:))
      .sorted(by: isSessionNewer(_:than:))
  }

  func projectLabel(for directory: String) -> String {
    if let projectName = projects.first(where: { $0.directory == directory })?.name.trimmedNonEmpty {
      return projectName
    }

    let lastPath = URL(fileURLWithPath: directory).lastPathComponent
    if let lastPath = lastPath.trimmedNonEmpty {
      return lastPath
    }

    return directory
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

  var visibleModelOptions: [ModelOption] {
    availableModels.filter { isModelVisible($0.selector) }
  }

  var selectedModelVariantDisplayName: String {
    guard let selectedModelVariant else {
      return "Default"
    }
    return selectedModelVariant.capitalized
  }

  var modelProviderGroups: [ModelProviderGroup] {
    let grouped = Dictionary(grouping: visibleModelOptions, by: \.providerID)
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

  var modelSettingsProviderGroups: [ModelProviderGroup] {
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

  func selectProject(_ projectID: String) {
    guard projects.contains(where: { $0.id == projectID }) else {
      return
    }

    selectedProjectID = projectID

    if let activeProject {
      connection.directory = activeProject.directory
    }

    Task {
      await refreshAgentAndModelOptions()
      await refreshPendingPrompts()
    }

    if let selectedSessionID, visibleSessions.contains(where: { $0.id == selectedSessionID }) {
      persistWorkspaceSettings()
      return
    }

    selectedSessionID = visibleSessions.first?.id
    if let selectedSessionID {
      Task {
        await selectSession(selectedSessionID)
      }
    }
    persistWorkspaceSettings()
  }

  @discardableResult
  func addProject(directory: String) -> Bool {
    guard let normalized = normalizedProjectDirectory(directory) else {
      return false
    }

    if let existing = projects.first(where: { $0.directory == normalized }) {
      selectProject(existing.id)
      return true
    }

    let project = Self.makeProject(directory: normalized)
    projects.append(project)
    projects.sort { lhs, rhs in
      lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
    selectedProjectID = project.id
    connection.directory = project.directory
    selectedSessionID = visibleSessions.first?.id
    if let selectedSessionID {
      Task {
        await selectSession(selectedSessionID)
      }
    }
    persistWorkspaceSettings()
    return true
  }

  func renameProject(projectID: String, name: String) {
    guard let normalizedName = name.trimmedNonEmpty else {
      return
    }

    guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }) else {
      return
    }

    guard projects[projectIndex].name != normalizedName else {
      return
    }

    projects[projectIndex].name = normalizedName
    projects.sort { lhs, rhs in
      lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
    persistWorkspaceSettings()
  }

  func setProjectSymbol(projectID: String, symbol: String?) {
    guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }) else {
      return
    }

    let normalizedSymbol = symbol?.trimmedNonEmpty
    guard projects[projectIndex].symbol != normalizedSymbol else {
      return
    }

    projects[projectIndex].symbol = normalizedSymbol
    persistWorkspaceSettings()
  }

  @discardableResult
  func removeProject(projectID: String) -> Bool {
    guard let removedProject = projects.first(where: { $0.id == projectID }) else {
      return false
    }

    let removedDirectory = removedProject.directory
    projects.removeAll { $0.id == projectID }

    let removedSessionIDs = Set(sessions.filter { $0.directory == removedDirectory }.map(\.id))
    if !removedSessionIDs.isEmpty {
      sessions.removeAll { removedSessionIDs.contains($0.id) }
      pinnedSessionIDs.subtract(removedSessionIDs)
      messagesBySession = messagesBySession.filter { !removedSessionIDs.contains($0.key) }
      messageLoadCountsBySession = messageLoadCountsBySession.filter { !removedSessionIDs.contains($0.key) }
      diffsBySession = diffsBySession.filter { !removedSessionIDs.contains($0.key) }
      sessionStatuses = sessionStatuses.filter { !removedSessionIDs.contains($0.key) }
      permissionsBySession = permissionsBySession.filter { !removedSessionIDs.contains($0.key) }
      questionsBySession = questionsBySession.filter { !removedSessionIDs.contains($0.key) }
      todosBySession = todosBySession.filter { !removedSessionIDs.contains($0.key) }
      sessionRefreshNeedsDiff.subtract(removedSessionIDs)

      for sessionID in removedSessionIDs {
        sessionRefreshTasks[sessionID]?.cancel()
        sessionRefreshTasks.removeValue(forKey: sessionID)
      }
    }

    if selectedProjectID == projectID {
      selectedProjectID = nil

      if let fallbackProjectID = projects.first?.id {
        selectProject(fallbackProjectID)
      } else {
        selectedSessionID = nil
        connection.directory = ""
        persistWorkspaceSettings()
      }

      return true
    }

    if let selectedSessionID, removedSessionIDs.contains(selectedSessionID) {
      self.selectedSessionID = visibleSessions.first?.id
      if let selectedSessionID = self.selectedSessionID {
        Task {
          await selectSession(selectedSessionID)
        }
      }
    }

    persistWorkspaceSettings()
    return true
  }

  func disconnect() {
    connection.disconnect()
  }

  func refreshSessions() async {
    guard let client = connection.client else { return }
    guard !isRefreshingSessions else { return }

    isRefreshingSessions = true
    defer {
      isRefreshingSessions = false
    }

    var nextSessions: [Session] = []

    for project in projects {
      do {
        var projectSessions = try await client.listSessions(directory: project.directory)
        projectSessions.sort(by: isSessionNewer(_:than:))
        nextSessions.append(contentsOf: projectSessions)
      } catch {
        connection.connectionError = error.localizedDescription
      }
    }

    nextSessions.sort(by: isSessionNewer(_:than:))

    sessions = nextSessions
    let activeSessionIDs = Set(nextSessions.filter { ($0.time.archived ?? 0) <= 0 }.map(\.id))
    let nextPinnedSessionIDs = pinnedSessionIDs.intersection(activeSessionIDs)
    if nextPinnedSessionIDs != pinnedSessionIDs {
      pinnedSessionIDs = nextPinnedSessionIDs
      persistWorkspaceSettings()
    }

    let validSessionIDs = Set(nextSessions.map(\.id))
    messagesBySession = messagesBySession.filter { validSessionIDs.contains($0.key) }
    messageLoadCountsBySession = messageLoadCountsBySession.filter { validSessionIDs.contains($0.key) }
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
  }

  func createSession(title: String? = nil) async {
    guard let client = connection.client else { return }
    guard !isCreatingSession else { return }

    isCreatingSession = true
    defer {
      isCreatingSession = false
    }

    do {
      let created = try await client.createSession(
        SessionCreateRequest(title: title),
        directory: activeProjectDirectory ?? connection.resolvedDirectory
      )
      selectedSessionID = created.id
      await refreshSessions()
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func createSession(inProjectID projectID: String, title: String? = nil) async {
    guard projects.contains(where: { $0.id == projectID }) else {
      return
    }

    if selectedProjectID != projectID {
      selectProject(projectID)
    }

    await createSession(title: title)
  }

  func selectSession(_ sessionID: String?) async {
    guard let sessionID else {
      selectedSessionID = nil
      return
    }

    guard let session = sessions.first(where: { $0.id == sessionID }) else {
      selectedSessionID = nil
      return
    }

    if let project = projects.first(where: { $0.directory == session.directory }), selectedProjectID != project.id {
      selectedProjectID = project.id
      connection.directory = project.directory
      persistWorkspaceSettings()
    }

    let shouldReload =
      selectedSessionID != sessionID ||
      messagesBySession[sessionID] == nil ||
      diffsBySession[sessionID] == nil

    selectedSessionID = sessionID

    guard shouldReload else {
      return
    }

    await loadMessages(sessionID: sessionID)
    await loadDiffs(sessionID: sessionID)
  }

  func loadMessages(sessionID: String, limit: Int? = nil) async {
    guard let client = connection.client else { return }

    beginLoadingMessages(for: sessionID)
    defer {
      endLoadingMessages(for: sessionID)
    }

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

  func isLoadingMessages(for sessionID: String) -> Bool {
    (messageLoadCountsBySession[sessionID] ?? 0) > 0
  }

  func loadDiffs(sessionID: String) async {
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

  func isSessionPinned(_ sessionID: String) -> Bool {
    pinnedSessionIDs.contains(sessionID)
  }

  func togglePinnedSession(_ sessionID: String) {
    guard sessions.contains(where: { $0.id == sessionID }) else {
      return
    }

    if pinnedSessionIDs.contains(sessionID) {
      pinnedSessionIDs.remove(sessionID)
    } else {
      pinnedSessionIDs.insert(sessionID)
    }

    persistWorkspaceSettings()
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
      let knownKeys = Set(options.map { modelVisibilityKey($0.selector) })
      hiddenModelKeys = hiddenModelKeys.intersection(knownKeys)
      reconcileSelectedModel(using: catalog.defaultModels)
      reconcileSelectedModelVariant()
      persistWorkspaceSettings()
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func selectAgent(named name: String) {
    selectedAgentName = name
    persistWorkspaceSettings()
  }

  func selectModel(_ option: ModelOption) {
    selectedModel = option.selector
    reconcileSelectedModelVariant()
    persistWorkspaceSettings()
  }

  func selectModelVariant(_ variant: String?) {
    selectedModelVariant = variant?.trimmedNonEmpty
    reconcileSelectedModelVariant()
    persistWorkspaceSettings()
  }

  func isModelVisible(_ option: ModelOption) -> Bool {
    isModelVisible(option.selector)
  }

  func setModelVisibility(_ option: ModelOption, isVisible: Bool) {
    let key = modelVisibilityKey(option.selector)

    if isVisible {
      hiddenModelKeys.remove(key)
    } else {
      if visibleModelOptions.count <= 1, isModelVisible(option.selector) {
        return
      }
      hiddenModelKeys.insert(key)
    }

    reconcileSelectedModel(using: [:])
    reconcileSelectedModelVariant()
    persistWorkspaceSettings()
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

    guard let client = connection.client else { return }
    do {
      _ = try await client.updateSession(
        id: sessionID,
        body: SessionUpdateRequest(title: trimmedTitle),
        directory: directoryForSessionAction(sessionID: sessionID)
      )
      await refreshSessions()
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func archiveSession(sessionID: String) async {
    let archiveTime = Date().timeIntervalSince1970 * 1000

    guard let client = connection.client else { return }
    do {
      _ = try await client.updateSession(
        id: sessionID,
        body: SessionUpdateRequest(time: SessionUpdateTime(archived: archiveTime)),
        directory: directoryForSessionAction(sessionID: sessionID)
      )
      await refreshSessions()
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func unarchiveSession(sessionID: String) async {
    guard let client = connection.client else { return }

    do {
      _ = try await client.updateSession(
        id: sessionID,
        body: SessionUpdateRequest(time: SessionUpdateTime.clearArchived()),
        directory: directoryForSessionAction(sessionID: sessionID)
      )
      await refreshSessions()
    } catch let OpenCodeClientError.httpStatus(code, _) where code == 400 || code == 422 {
      connection.connectionError = "This OpenCode server version does not support unarchiving yet. Update the server and try again."
    } catch {
      connection.connectionError = error.localizedDescription
    }
  }

  func deleteSession(sessionID: String) async {
    guard let client = connection.client else { return }
    do {
      _ = try await client.deleteSession(id: sessionID, directory: directoryForSessionAction(sessionID: sessionID))
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

  func reconcileSelectedModel(using defaultModels: [String: String]) {
    let visibleOptions = visibleModelOptions

    if
      let selectedModel,
      visibleOptions.contains(where: {
        $0.providerID == selectedModel.providerID && $0.modelID == selectedModel.modelID
      })
    {
      return
    }

    for (providerID, modelID) in defaultModels {
      if let match = visibleOptions.first(where: { $0.providerID == providerID && $0.modelID == modelID }) {
        selectedModel = match.selector
        return
      }
    }

    selectedModel = visibleOptions.first?.selector ?? availableModels.first?.selector
  }

  func reconcileSelectedModelVariant() {
    guard let selectedModelVariant else {
      return
    }

    guard selectedModelVariants.contains(selectedModelVariant) else {
      self.selectedModelVariant = nil
      return
    }
  }

  private func isModelVisible(_ selector: ModelSelector) -> Bool {
    !hiddenModelKeys.contains(modelVisibilityKey(selector))
  }

  func modelVisibilityKey(_ selector: ModelSelector) -> String {
    "\(selector.providerID)::\(selector.modelID)"
  }

  private func directoryForSessionAction(sessionID: String) -> String? {
    if let sessionDirectory = sessions.first(where: { $0.id == sessionID })?.directory.trimmedNonEmpty {
      return sessionDirectory
    }

    return connection.resolvedDirectory
  }

  private func isVisibleRootSession(_ session: Session) -> Bool {
    session.parentID == nil && (session.time.archived ?? 0) <= 0
  }

  private func isSessionNewer(_ lhs: Session, than rhs: Session) -> Bool {
    let lhsUpdated = lhs.time.updated ?? lhs.time.created ?? 0
    let rhsUpdated = rhs.time.updated ?? rhs.time.created ?? 0

    if lhsUpdated != rhsUpdated {
      return lhsUpdated > rhsUpdated
    }

    return lhs.id > rhs.id
  }

  private func beginLoadingMessages(for sessionID: String) {
    messageLoadCountsBySession[sessionID, default: 0] += 1
  }

  private func endLoadingMessages(for sessionID: String) {
    guard let currentCount = messageLoadCountsBySession[sessionID] else {
      return
    }

    if currentCount <= 1 {
      messageLoadCountsBySession.removeValue(forKey: sessionID)
    } else {
      messageLoadCountsBySession[sessionID] = currentCount - 1
    }
  }

  private func normalizedProjectDirectory(_ raw: String) -> String? {
    let expanded = (raw as NSString).expandingTildeInPath
    let trimmed = expanded.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return nil
    }

    let normalized = URL(fileURLWithPath: trimmed).standardizedFileURL.path

    if connection.isConnected {
      return normalized
    }

    var isDirectory = ObjCBool(false)
    guard FileManager.default.fileExists(atPath: normalized, isDirectory: &isDirectory), isDirectory.boolValue else {
      return nil
    }

    return normalized
  }

  private func persistWorkspaceSettings() {
    guard allowsPersistence else {
      return
    }

    connection.persistSettingsBestEffort(
      selectedAgentName: selectedAgentName,
      selectedModel: selectedModel,
      selectedModelVariant: selectedModelVariant,
      hiddenModelKeys: hiddenModelKeys,
      pinnedSessionIDs: pinnedSessionIDs,
      projects: projects,
      selectedProjectID: selectedProjectID,
      showReasoningSummaries: showReasoningSummaries,
      expandShellToolParts: expandShellToolParts,
      expandEditToolParts: expandEditToolParts
    )
  }

  private static func makeProject(directory: String) -> SavedProject {
    let url = URL(fileURLWithPath: directory)
    let name = url.lastPathComponent.isEmpty ? directory : url.lastPathComponent
    return SavedProject(id: "prj_\(UUID().uuidString.lowercased())", name: name, directory: directory)
  }
}
