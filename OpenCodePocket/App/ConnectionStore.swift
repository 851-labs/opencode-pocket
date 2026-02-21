import Foundation
import Observation
import OpenCodeModels
import OpenCodeNetworking

@MainActor
@Observable
final class ConnectionStore {
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

  private(set) var client: OpenCodeClient?
  weak var workspace: WorkspaceStore?

  let isMockWorkspace: Bool
  let initialSelectedAgentName: String
  let initialSelectedModel: ModelSelector?
  let initialSelectedModelVariant: String?

  private let settingsStore: ConnectionSettingsStore

  init(settingsStore: ConnectionSettingsStore = ConnectionSettingsStore()) {
    self.settingsStore = settingsStore

    let processInfo = ProcessInfo.processInfo
    let isRunningUITests = processInfo.environment["XCTestConfigurationFilePath"] != nil
    let isExplicitConnectUITest = processInfo.arguments.contains("-ui-testing")
    isMockWorkspace =
      processInfo.arguments.contains("-ui-testing-workspace") ||
      processInfo.environment["OPENCODE_POCKET_UI_TEST_WORKSPACE"] == "1" ||
      (isRunningUITests && !isExplicitConnectUITest)

    let settings = settingsStore.loadSettings()
    baseURL = settings.baseURL
    username = settings.username
    useBasicAuth = settings.useBasicAuth
    directory = settings.directory
    password = settingsStore.loadPassword(baseURL: settings.baseURL, username: settings.username) ?? ""

    initialSelectedAgentName = settings.selectedAgent ?? "build"

    if
      let selectedProviderID = settings.selectedProviderID,
      let selectedModelID = settings.selectedModelID
    {
      initialSelectedModel = ModelSelector(providerID: selectedProviderID, modelID: selectedModelID)
    } else {
      initialSelectedModel = nil
    }

    initialSelectedModelVariant = settings.selectedModelVariant?.trimmedNonEmpty
  }

  var resolvedDirectory: String? {
    directory.trimmedNonEmpty
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
          directory: resolvedDirectory
        )
      )

      let health = try await nextClient.health()

      client = nextClient
      isConnected = health.healthy
      serverVersion = health.version
      eventConnectionState = "Connected"

      saveConnectionSettings(
        using: normalizedURL.absoluteString,
        selectedAgentName: workspace?.selectedAgentName.trimmedNonEmpty,
        selectedModel: workspace?.selectedModel,
        selectedModelVariant: workspace?.selectedModelVariant
      )

      await workspace?.refreshAgentAndModelOptions()
      await workspace?.refreshSessions()
      workspace?.startEventSubscriptionLoop()
    } catch {
      isConnected = false
      eventConnectionState = "Disconnected"
      connectionError = error.localizedDescription
    }
  }

  func disconnect() {
    workspace?.stopEventSubscriptionLoop()
    workspace?.clearSessionRefreshState()
    workspace?.sessionStatuses.removeAll()
    workspace?.permissionsBySession.removeAll()
    workspace?.questionsBySession.removeAll()
    workspace?.todosBySession.removeAll()
    client = nil
    isConnected = false
    eventConnectionState = "Disconnected"
  }

  func persistSettingsBestEffort(
    selectedAgentName: String,
    selectedModel: ModelSelector?,
    selectedModelVariant: String?
  ) {
    let normalized: String
    if let url = try? normalizedBaseURL() {
      normalized = url.absoluteString
    } else {
      normalized = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    guard !normalized.isEmpty else { return }

    saveConnectionSettings(
      using: normalized,
      selectedAgentName: selectedAgentName.trimmedNonEmpty,
      selectedModel: selectedModel,
      selectedModelVariant: selectedModelVariant?.trimmedNonEmpty
    )
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

  private func saveConnectionSettings(
    using normalizedBaseURL: String,
    selectedAgentName: String?,
    selectedModel: ModelSelector?,
    selectedModelVariant: String?
  ) {
    let settings = ConnectionSettings(
      baseURL: normalizedBaseURL,
      username: username,
      useBasicAuth: useBasicAuth,
      directory: directory,
      selectedAgent: selectedAgentName,
      selectedProviderID: selectedModel?.providerID,
      selectedModelID: selectedModel?.modelID,
      selectedModelVariant: selectedModelVariant
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
}
