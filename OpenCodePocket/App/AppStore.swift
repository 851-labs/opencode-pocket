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
    var sessionStatuses: [String: String] = [:]

    var draftMessage = ""
    var isSending = false
    var isCreatingSession = false
    var isRefreshingSessions = false

    private var client: OpenCodeClient?
    private var eventsTask: Task<Void, Never>?
    private var debouncedMessageRefreshTask: Task<Void, Never>?

    private let settingsStore: ConnectionSettingsStore

    init(settingsStore: ConnectionSettingsStore = ConnectionSettingsStore()) {
        self.settingsStore = settingsStore
        let settings = settingsStore.loadSettings()
        self.baseURL = settings.baseURL
        self.username = settings.username
        self.useBasicAuth = settings.useBasicAuth
        self.directory = settings.directory
        self.password = settingsStore.loadPassword(baseURL: settings.baseURL, username: settings.username) ?? ""
    }

    var selectedMessages: [MessageEnvelope] {
        guard let selectedSessionID else { return [] }
        return messagesBySession[selectedSessionID] ?? []
    }

    func connect() async {
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
        debouncedMessageRefreshTask?.cancel()
        debouncedMessageRefreshTask = nil
        client = nil
        isConnected = false
        eventConnectionState = "Disconnected"
        sessionStatuses.removeAll()
    }

    func refreshSessions() async {
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

            if let selectedSessionID, sessions.contains(where: { $0.id == selectedSessionID }) {
                await loadMessages(sessionID: selectedSessionID)
            } else {
                selectedSessionID = sessions.first?.id
                if let selectedSessionID {
                    await loadMessages(sessionID: selectedSessionID)
                }
            }
        } catch {
            connectionError = error.localizedDescription
        }
    }

    func createSession(title: String? = nil) async {
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
    }

    func loadMessages(sessionID: String, limit: Int? = nil) async {
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

    func sendDraftMessage(in sessionID: String) async {
        guard let client else { return }
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let original = trimmed
        draftMessage = ""
        isSending = true

        defer {
            isSending = false
        }

        do {
            let request = PromptRequest(parts: [.text(original)])
            try await client.sendMessageAsync(sessionID: sessionID, body: request, directory: directory.trimmedNonEmpty)

            try? await Task.sleep(nanoseconds: 200_000_000)
            await loadMessages(sessionID: sessionID)
        } catch {
            connectionError = error.localizedDescription
            draftMessage = original
        }
    }

    func abort(sessionID: String) async {
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
            directory: directory
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
                scheduleMessageRefresh(sessionID: sessionID)
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

        case "message.updated", "message.part.updated", "message.part.removed", "message.removed", "session.diff":
            scheduleMessageRefresh(sessionID: selectedSessionID)

        default:
            break
        }
    }

    private func scheduleMessageRefresh(sessionID: String?) {
        guard let sessionID else { return }

        debouncedMessageRefreshTask?.cancel()
        debouncedMessageRefreshTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            await self?.loadMessages(sessionID: sessionID)
        }
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
