import Foundation
import Observation

@MainActor
@Observable
final class AppStore {
    var baseURL: String
    var username: String
    var password: String
    var useBasicAuth: Bool
    var directory: String

    var isConnecting = false
    var isConnected = false
    var serverVersion: String?
    var connectionError: String?
    var eventConnectionState = "Disconnected"

    var sessions: [Session] = []
    var selectedSessionID: String?
    var messagesBySession: [String: [MessageEnvelope]] = [:]
    var diffsBySession: [String: [FileDiff]] = [:]
    var sessionStatuses: [String: String] = [:]

    var availableAgents: [AgentDescriptor] = []
    var availableModels: [ModelOption] = []
    var selectedAgentName: String
    var selectedModel: ModelSelector?

    var draftMessage = ""
    var isSending = false
    var isCreatingSession = false
    var isRefreshingSessions = false

    private var client: OpenCodeClient?
    private var eventsTask: Task<Void, Never>?
    private var debouncedSessionRefreshTask: Task<Void, Never>?

    private let settingsStore: ConnectionSettingsStore
    private let isMockWorkspace: Bool

    init(settingsStore: ConnectionSettingsStore = ConnectionSettingsStore()) {
        self.settingsStore = settingsStore
        let processInfo = ProcessInfo.processInfo
        let isRunningUITests = processInfo.environment["XCTestConfigurationFilePath"] != nil
        let isExplicitConnectUITest = processInfo.arguments.contains("-ui-testing")
        self.isMockWorkspace =
            processInfo.arguments.contains("-ui-testing-workspace") ||
            processInfo.environment["OPENCODE_POCKET_UI_TEST_WORKSPACE"] == "1" ||
            (isRunningUITests && !isExplicitConnectUITest)

        let settings = settingsStore.loadSettings()
        self.baseURL = settings.baseURL
        self.username = settings.username
        self.useBasicAuth = settings.useBasicAuth
        self.directory = settings.directory
        self.password = settingsStore.loadPassword(baseURL: settings.baseURL, username: settings.username) ?? ""
        self.selectedAgentName = settings.selectedAgent ?? "build"

        if
            let selectedProviderID = settings.selectedProviderID,
            let selectedModelID = settings.selectedModelID
        {
            self.selectedModel = ModelSelector(providerID: selectedProviderID, modelID: selectedModelID)
        } else {
            self.selectedModel = nil
        }

        if isMockWorkspace {
            seedMockWorkspace()
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

    func connect() async {
        if isMockWorkspace {
            return
        }

        guard !isConnecting else { return }

        isConnecting = true
        connectionError = nil

        defer {
            isConnecting = false
        }

        do {
            let normalizedURL = try normalizedBaseURL()

            let resolvedUsername = username.trimmedNonEmpty
            let resolvedPassword: String?

            if useBasicAuth {
                if let directPassword = password.trimmedNonEmpty {
                    resolvedPassword = directPassword
                } else if let resolvedUsername {
                    resolvedPassword = settingsStore.loadPassword(baseURL: normalizedURL.absoluteString, username: resolvedUsername)
                    password = resolvedPassword ?? ""
                } else {
                    resolvedPassword = nil
                }
            } else {
                resolvedPassword = nil
            }

            let nextClient = OpenCodeClient(
                configuration: OpenCodeClientConfiguration(
                    baseURL: normalizedURL,
                    username: useBasicAuth ? resolvedUsername : nil,
                    password: useBasicAuth ? resolvedPassword : nil,
                    directory: directory.trimmedNonEmpty
                )
            )

            let health = try await nextClient.health()

            client = nextClient
            isConnected = health.healthy
            serverVersion = health.version
            eventConnectionState = "Connected"

            saveConnectionSettings(using: normalizedURL.absoluteString)

            await refreshAgentAndModelOptions()
            await refreshSessions()
            startEventSubscriptionLoop()
        } catch {
            isConnected = false
            eventConnectionState = "Disconnected"
            connectionError = error.localizedDescription
        }
    }

    func disconnect() {
        eventsTask?.cancel()
        eventsTask = nil
        debouncedSessionRefreshTask?.cancel()
        debouncedSessionRefreshTask = nil
        client = nil
        isConnected = false
        eventConnectionState = "Disconnected"
        sessionStatuses.removeAll()
    }

    func refreshSessions() async {
        if isMockWorkspace {
            sessions.sort { $0.sortTimestamp > $1.sortTimestamp }
            if let selectedSessionID, visibleSessions.contains(where: { $0.id == selectedSessionID }) {
                return
            }
            selectedSessionID = visibleSessions.first?.id
            return
        }

        guard let client else { return }
        guard !isRefreshingSessions else { return }

        isRefreshingSessions = true
        defer {
            isRefreshingSessions = false
        }

        do {
            var nextSessions = try await client.listSessions(directory: directory.trimmedNonEmpty)
            nextSessions.sort { $0.sortTimestamp > $1.sortTimestamp }

            sessions = nextSessions
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
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func createSession(title: String? = nil) async {
        if isMockWorkspace {
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
            return
        }

        guard let client else { return }
        guard !isCreatingSession else { return }

        isCreatingSession = true
        defer {
            isCreatingSession = false
        }

        do {
            let created = try await client.createSession(
                SessionCreateRequest(title: title),
                directory: directory.trimmedNonEmpty
            )
            selectedSessionID = created.id
            await refreshSessions()
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func selectSession(_ sessionID: String?) async {
        guard let sessionID else { return }
        selectedSessionID = sessionID
        await loadMessages(sessionID: sessionID)
        await loadDiffs(sessionID: sessionID)
    }

    func loadMessages(sessionID: String, limit: Int? = nil) async {
        if isMockWorkspace { return }
        guard let client else { return }

        do {
            let messages = try await client.listMessages(
                sessionID: sessionID,
                limit: limit,
                directory: directory.trimmedNonEmpty
            )
            messagesBySession[sessionID] = messages
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func loadDiffs(sessionID: String) async {
        if isMockWorkspace { return }
        guard let client else { return }

        do {
            let diffs = try await client.getSessionDiff(sessionID: sessionID, directory: directory.trimmedNonEmpty)
            diffsBySession[sessionID] = diffs
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func sendDraftMessage(in sessionID: String) async {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if isMockWorkspace {
            draftMessage = ""
            if let userMessage = makeMockMessage(sessionID: sessionID, role: .user, text: trimmed) {
                messagesBySession[sessionID, default: []].append(userMessage)
            }
            if let assistantMessage = makeMockMessage(sessionID: sessionID, role: .assistant, text: "Mock response for \"\(trimmed)\".") {
                messagesBySession[sessionID, default: []].append(assistantMessage)
            }
            return
        }

        guard let client else { return }
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
                parts: [.text(original)]
            )
            try await client.sendMessageAsync(sessionID: sessionID, body: request, directory: directory.trimmedNonEmpty)

            try? await Task.sleep(nanoseconds: 200_000_000)
            await loadMessages(sessionID: sessionID)
            await loadDiffs(sessionID: sessionID)
        } catch {
            connectionError = error.localizedDescription
            draftMessage = original
        }
    }

    func abort(sessionID: String) async {
        if isMockWorkspace {
            sessionStatuses[sessionID] = "idle"
            return
        }

        guard let client else { return }
        do {
            _ = try await client.abortSession(sessionID: sessionID, directory: directory.trimmedNonEmpty)
            sessionStatuses[sessionID] = "idle"
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func sessionTitle(for sessionID: String) -> String {
        sessions.first(where: { $0.id == sessionID })?.title ?? "Session"
    }

    func statusLabel(for sessionID: String) -> String {
        sessionStatuses[sessionID] ?? "idle"
    }

    func isSessionRunning(_ sessionID: String) -> Bool {
        switch statusLabel(for: sessionID) {
        case "busy", "retry":
            return true
        default:
            return false
        }
    }

    func refreshAgentAndModelOptions() async {
        guard let client else { return }

        do {
            let allAgents = try await client.listAgents(directory: directory.trimmedNonEmpty)
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
            connectionError = error.localizedDescription
        }

        do {
            let catalog = try await client.listConfigProviders(directory: directory.trimmedNonEmpty)
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
            persistSettingsBestEffort()
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func selectAgent(named name: String) {
        selectedAgentName = name
        persistSettingsBestEffort()
    }

    func selectModel(_ option: ModelOption) {
        selectedModel = option.selector
        persistSettingsBestEffort()
    }

    func renameSession(sessionID: String, title: String) async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        if isMockWorkspace {
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

        guard let client else { return }
        do {
            _ = try await client.updateSession(
                id: sessionID,
                body: SessionUpdateRequest(title: trimmedTitle),
                directory: directory.trimmedNonEmpty
            )
            await refreshSessions()
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func archiveSession(sessionID: String) async {
        let archiveTime = Date().timeIntervalSince1970 * 1000

        if isMockWorkspace {
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

        guard let client else { return }
        do {
            _ = try await client.updateSession(
                id: sessionID,
                body: SessionUpdateRequest(time: SessionUpdateTime(archived: archiveTime)),
                directory: directory.trimmedNonEmpty
            )
            await refreshSessions()
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func deleteSession(sessionID: String) async {
        if isMockWorkspace {
            sessions.removeAll { $0.id == sessionID }
            messagesBySession[sessionID] = nil
            diffsBySession[sessionID] = nil
            sessionStatuses[sessionID] = nil
            if selectedSessionID == sessionID {
                selectedSessionID = visibleSessions.first?.id
            }
            return
        }

        guard let client else { return }
        do {
            _ = try await client.deleteSession(id: sessionID, directory: directory.trimmedNonEmpty)
            messagesBySession[sessionID] = nil
            diffsBySession[sessionID] = nil
            sessionStatuses[sessionID] = nil
            await refreshSessions()
        } catch {
            connectionError = error.localizedDescription
        }
    }

    private func normalizedBaseURL() throws -> URL {
        var value = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            throw OpenCodeClientError.message("Server URL is required")
        }

        if !value.contains("://") {
            value = "http://\(value)"
        }

        guard let url = URL(string: value), let scheme = url.scheme, !scheme.isEmpty else {
            throw OpenCodeClientError.invalidURL(value)
        }

        return url
    }

    private func saveConnectionSettings(using normalizedBaseURL: String) {
        let settings = ConnectionSettings(
            baseURL: normalizedBaseURL,
            username: username,
            useBasicAuth: useBasicAuth,
            directory: directory,
            selectedAgent: selectedAgentName.trimmedNonEmpty,
            selectedProviderID: selectedModel?.providerID,
            selectedModelID: selectedModel?.modelID
        )
        settingsStore.saveSettings(settings)

        if
            useBasicAuth,
            let resolvedUsername = username.trimmedNonEmpty,
            let resolvedPassword = password.trimmedNonEmpty
        {
            settingsStore.savePassword(resolvedPassword, baseURL: normalizedBaseURL, username: resolvedUsername)
        } else if let resolvedUsername = username.trimmedNonEmpty {
            settingsStore.deletePassword(baseURL: normalizedBaseURL, username: resolvedUsername)
        }
    }

    private func startEventSubscriptionLoop() {
        eventsTask?.cancel()
        guard let client else { return }

        eventsTask = Task { [weak self] in
            guard let self else { return }
            let stream = client.subscribeEvents(directory: directory.trimmedNonEmpty)

            for await event in stream {
                await self.handle(event: event)
            }
        }
    }

    private func handle(event: ServerEvent) async {
        switch event.type {
        case "server.connected":
            eventConnectionState = "Live updates connected"

        case "session.created", "session.updated", "session.deleted":
            await refreshSessions()

        case "session.idle":
            if let sessionID = event.properties.objectValue?.string(for: "sessionID") {
                sessionStatuses[sessionID] = "idle"
                scheduleSessionRefresh(sessionID: sessionID)
            }

        case "session.status":
            guard
                let properties = event.properties.objectValue,
                let sessionID = properties.string(for: "sessionID")
            else {
                return
            }

            let status = properties
                .object(for: "status")?
                .string(for: "type") ?? "unknown"
            sessionStatuses[sessionID] = status

        case "session.error":
            guard let properties = event.properties.objectValue else { return }
            if let sessionID = properties.string(for: "sessionID") {
                sessionStatuses[sessionID] = "error"
            }
            if let errorObject = properties.object(for: "error") {
                connectionError = JSONValue.object(errorObject).compactDescription
            }

        case "session.diff":
            guard
                let properties = event.properties.objectValue,
                let sessionID = properties.string(for: "sessionID")
            else {
                return
            }

            if
                let diffValue = properties["diff"],
                let data = try? JSONEncoder().encode(diffValue),
                let decoded = try? JSONDecoder().decode([FileDiff].self, from: data)
            {
                diffsBySession[sessionID] = decoded
            } else {
                scheduleSessionRefresh(sessionID: sessionID)
            }

        case "message.updated", "message.part.updated", "message.part.removed", "message.removed":
            scheduleSessionRefresh(sessionID: selectedSessionID)

        default:
            break
        }
    }

    private func scheduleSessionRefresh(sessionID: String?) {
        guard let sessionID else { return }

        debouncedSessionRefreshTask?.cancel()
        debouncedSessionRefreshTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            await self?.loadMessages(sessionID: sessionID)
            await self?.loadDiffs(sessionID: sessionID)
        }
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

    private func persistSettingsBestEffort() {
        let normalized: String
        if let url = try? normalizedBaseURL() {
            normalized = url.absoluteString
        } else {
            normalized = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !normalized.isEmpty else { return }
        saveConnectionSettings(using: normalized)
    }

    private func seedMockWorkspace() {
        let now = Date().timeIntervalSince1970 * 1000

        let primary = Session(
            id: "ses_mock_primary",
            slug: "mock-primary",
            projectID: "prj_mock",
            directory: "/tmp/opencode-pocket",
            parentID: nil,
            title: "Mock Workspace Session",
            version: "1",
            time: SessionTime(created: now - 50_000, updated: now - 5_000, archived: nil),
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
            time: SessionTime(created: now - 140_000, updated: now - 40_000, archived: nil),
            summary: nil,
            share: nil,
            revert: nil
        )

        sessions = [primary, secondary]
        selectedSessionID = primary.id
        sessionStatuses[primary.id] = "idle"
        sessionStatuses[secondary.id] = "idle"
        diffsBySession[primary.id] = [
            FileDiff(file: "OpenCodePocket/App/AppStore.swift", before: "", after: "", additions: 24, deletions: 9, status: "modified"),
            FileDiff(file: "OpenCodePocket/Features/WorkspaceView.swift", before: "", after: "", additions: 108, deletions: 0, status: "added")
        ]
        diffsBySession[secondary.id] = []
        availableAgents = [
            AgentDescriptor(name: "build", description: "Executes tools based on configured permissions.", mode: "primary", hidden: false),
            AgentDescriptor(name: "plan", description: "Planning mode with edit restrictions.", mode: "primary", hidden: false)
        ]
        availableModels = [
            ModelOption(providerID: "openai", providerName: "OpenAI", modelID: "gpt-5.3-codex", modelName: "GPT-5.3 Codex", variants: ["low", "medium", "high"]),
            ModelOption(providerID: "anthropic", providerName: "Anthropic", modelID: "claude-sonnet-4-5", modelName: "Claude Sonnet 4.5", variants: ["high", "max"])
        ]

        if !availableAgents.contains(where: { $0.name == selectedAgentName }) {
            selectedAgentName = "build"
        }
        selectedModel = availableModels.first?.selector

        if let greeting = makeMockMessage(sessionID: primary.id, role: .assistant, text: "Welcome to the mock workspace.") {
            messagesBySession[primary.id] = [greeting]
        }

        isConnected = true
        eventConnectionState = "Mock workspace"
        serverVersion = "mock"
        connectionError = nil
    }

    private func makeMockMessage(sessionID: String, role: MessageRole, text: String) -> MessageEnvelope? {
        let messageID = "msg_mock_\(UUID().uuidString.prefix(10))"

        let payload: [String: Any] = [
            "info": [
                "id": messageID,
                "sessionID": sessionID,
                "role": role.rawValue,
                "agent": selectedAgentName
            ],
            "parts": [
                [
                    "id": "prt_mock_\(UUID().uuidString.prefix(10))",
                    "sessionID": sessionID,
                    "messageID": messageID,
                    "type": "text",
                    "text": text
                ]
            ]
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

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
