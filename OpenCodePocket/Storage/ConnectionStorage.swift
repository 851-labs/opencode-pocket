import Foundation
import Security

struct SavedProject: Codable, Equatable, Identifiable {
  var id: String
  var name: String
  var directory: String
  var symbol: String? = nil
}

struct ConnectionSettings: Codable, Equatable {
  var baseURL: String
  var username: String
  var useBasicAuth: Bool
  var directory: String

  init(
    baseURL: String,
    username: String,
    useBasicAuth: Bool,
    directory: String
  ) {
    self.baseURL = baseURL
    self.username = username
    self.useBasicAuth = useBasicAuth
    self.directory = directory
  }

  private enum CodingKeys: String, CodingKey {
    case baseURL
    case username
    case useBasicAuth
    case directory
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL) ?? Self.default.baseURL
    username = try container.decodeIfPresent(String.self, forKey: .username) ?? Self.default.username
    useBasicAuth = try container.decodeIfPresent(Bool.self, forKey: .useBasicAuth) ?? Self.default.useBasicAuth
    directory = try container.decodeIfPresent(String.self, forKey: .directory) ?? Self.default.directory
  }

  static let `default` = ConnectionSettings(
    baseURL: "http://claudl.taile64ce5.ts.net:4096",
    username: "opencode",
    useBasicAuth: false,
    directory: ""
  )
}

struct WorkspaceSettings: Codable, Equatable {
  var selectedAgent: String?
  var selectedProviderID: String?
  var selectedModelID: String?
  var selectedModelVariant: String?
  var hiddenModelKeys: [String]
  var pinnedSessionIDs: [String]
  var projects: [SavedProject]
  var selectedProjectID: String?
  var showReasoningSummaries: Bool
  var expandShellToolParts: Bool
  var expandEditToolParts: Bool
  var notifyAgentSystemNotifications: Bool
  var notifyPermissionSystemNotifications: Bool
  var notifyErrorSystemNotifications: Bool

  init(
    selectedAgent: String?,
    selectedProviderID: String?,
    selectedModelID: String?,
    selectedModelVariant: String?,
    hiddenModelKeys: [String],
    pinnedSessionIDs: [String] = [],
    projects: [SavedProject],
    selectedProjectID: String?,
    showReasoningSummaries: Bool = false,
    expandShellToolParts: Bool = true,
    expandEditToolParts: Bool = false,
    notifyAgentSystemNotifications: Bool = true,
    notifyPermissionSystemNotifications: Bool = true,
    notifyErrorSystemNotifications: Bool = false
  ) {
    self.selectedAgent = selectedAgent
    self.selectedProviderID = selectedProviderID
    self.selectedModelID = selectedModelID
    self.selectedModelVariant = selectedModelVariant
    self.hiddenModelKeys = hiddenModelKeys
    self.pinnedSessionIDs = pinnedSessionIDs
    self.projects = projects
    self.selectedProjectID = selectedProjectID
    self.showReasoningSummaries = showReasoningSummaries
    self.expandShellToolParts = expandShellToolParts
    self.expandEditToolParts = expandEditToolParts
    self.notifyAgentSystemNotifications = notifyAgentSystemNotifications
    self.notifyPermissionSystemNotifications = notifyPermissionSystemNotifications
    self.notifyErrorSystemNotifications = notifyErrorSystemNotifications
  }

  static let `default` = WorkspaceSettings(
    selectedAgent: nil,
    selectedProviderID: nil,
    selectedModelID: nil,
    selectedModelVariant: nil,
    hiddenModelKeys: [],
    pinnedSessionIDs: [],
    projects: [],
    selectedProjectID: nil,
    showReasoningSummaries: false,
    expandShellToolParts: true,
    expandEditToolParts: false,
    notifyAgentSystemNotifications: true,
    notifyPermissionSystemNotifications: true,
    notifyErrorSystemNotifications: false
  )
}

final class ConnectionSettingsStore {
  private let defaults: UserDefaults
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  private static let defaultsKey = "connection.settings.v1"
  private static let keychainService = "sh.851.opencode-pocket"

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func loadSettings() -> ConnectionSettings {
    guard
      let data = defaults.data(forKey: Self.defaultsKey),
      let settings = try? decoder.decode(ConnectionSettings.self, from: data)
    else {
      return .default
    }
    return settings
  }

  func saveSettings(_ settings: ConnectionSettings) {
    guard let data = try? encoder.encode(settings) else { return }
    defaults.set(data, forKey: Self.defaultsKey)
  }

  func hasSavedSettings() -> Bool {
    defaults.data(forKey: Self.defaultsKey) != nil
  }

  func loadPassword(baseURL: String, username: String) -> String? {
    let account = accountKey(baseURL: baseURL, username: username)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.keychainService,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard
      status == errSecSuccess,
      let data = item as? Data,
      let password = String(data: data, encoding: .utf8)
    else {
      return nil
    }
    return password
  }

  func savePassword(_ password: String, baseURL: String, username: String) {
    let account = accountKey(baseURL: baseURL, username: username)
    let passwordData = Data(password.utf8)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.keychainService,
      kSecAttrAccount as String: account,
    ]

    SecItemDelete(query as CFDictionary)

    var addQuery = query
    addQuery[kSecValueData as String] = passwordData
    SecItemAdd(addQuery as CFDictionary, nil)
  }

  func deletePassword(baseURL: String, username: String) {
    let account = accountKey(baseURL: baseURL, username: username)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.keychainService,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(query as CFDictionary)
  }

  private func accountKey(baseURL: String, username: String) -> String {
    "\(baseURL.lowercased())::\(username.lowercased())"
  }
}

final class WorkspaceSettingsStore {
  private let defaults: UserDefaults
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  private static let defaultsKey = "workspace.settings.v1"
  private static let legacyDefaultsKey = "connection.settings.v1"

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func loadSettings() -> WorkspaceSettings {
    if
      let data = defaults.data(forKey: Self.defaultsKey),
      let settings = try? decoder.decode(WorkspaceSettings.self, from: data)
    {
      return settings
    }

    if
      let legacyData = defaults.data(forKey: Self.legacyDefaultsKey),
      let legacy = try? decoder.decode(LegacyConnectionSettings.self, from: legacyData)
    {
      return WorkspaceSettings(
        selectedAgent: legacy.selectedAgent,
        selectedProviderID: legacy.selectedProviderID,
        selectedModelID: legacy.selectedModelID,
        selectedModelVariant: legacy.selectedModelVariant,
        hiddenModelKeys: legacy.hiddenModelKeys,
        pinnedSessionIDs: legacy.pinnedSessionIDs,
        projects: legacy.projects,
        selectedProjectID: legacy.selectedProjectID,
        showReasoningSummaries: legacy.showReasoningSummaries,
        expandShellToolParts: legacy.expandShellToolParts,
        expandEditToolParts: legacy.expandEditToolParts,
        notifyAgentSystemNotifications: legacy.notifyAgentSystemNotifications,
        notifyPermissionSystemNotifications: legacy.notifyPermissionSystemNotifications,
        notifyErrorSystemNotifications: legacy.notifyErrorSystemNotifications
      )
    }

    return .default
  }

  func saveSettings(_ settings: WorkspaceSettings) {
    guard let data = try? encoder.encode(settings) else { return }
    defaults.set(data, forKey: Self.defaultsKey)
  }
}

private struct LegacyConnectionSettings: Codable {
  var selectedAgent: String?
  var selectedProviderID: String?
  var selectedModelID: String?
  var selectedModelVariant: String?
  var hiddenModelKeys: [String]
  var pinnedSessionIDs: [String]
  var projects: [SavedProject]
  var selectedProjectID: String?
  var showReasoningSummaries: Bool
  var expandShellToolParts: Bool
  var expandEditToolParts: Bool
  var notifyAgentSystemNotifications: Bool
  var notifyPermissionSystemNotifications: Bool
  var notifyErrorSystemNotifications: Bool

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    selectedAgent = try container.decodeIfPresent(String.self, forKey: .selectedAgent)
    selectedProviderID = try container.decodeIfPresent(String.self, forKey: .selectedProviderID)
    selectedModelID = try container.decodeIfPresent(String.self, forKey: .selectedModelID)
    selectedModelVariant = try container.decodeIfPresent(String.self, forKey: .selectedModelVariant)
    hiddenModelKeys = try container.decodeIfPresent([String].self, forKey: .hiddenModelKeys) ?? []
    pinnedSessionIDs = try container.decodeIfPresent([String].self, forKey: .pinnedSessionIDs) ?? []
    projects = try container.decodeIfPresent([SavedProject].self, forKey: .projects) ?? []
    selectedProjectID = try container.decodeIfPresent(String.self, forKey: .selectedProjectID)
    showReasoningSummaries = try container.decodeIfPresent(Bool.self, forKey: .showReasoningSummaries) ?? false
    expandShellToolParts = try container.decodeIfPresent(Bool.self, forKey: .expandShellToolParts) ?? true
    expandEditToolParts = try container.decodeIfPresent(Bool.self, forKey: .expandEditToolParts) ?? false
    notifyAgentSystemNotifications = try container.decodeIfPresent(Bool.self, forKey: .notifyAgentSystemNotifications) ?? true
    notifyPermissionSystemNotifications =
      try container.decodeIfPresent(Bool.self, forKey: .notifyPermissionSystemNotifications) ?? true
    notifyErrorSystemNotifications = try container.decodeIfPresent(Bool.self, forKey: .notifyErrorSystemNotifications) ?? false
  }

  private enum CodingKeys: String, CodingKey {
    case selectedAgent
    case selectedProviderID
    case selectedModelID
    case selectedModelVariant
    case hiddenModelKeys
    case pinnedSessionIDs
    case projects
    case selectedProjectID
    case showReasoningSummaries
    case expandShellToolParts
    case expandEditToolParts
    case notifyAgentSystemNotifications
    case notifyPermissionSystemNotifications
    case notifyErrorSystemNotifications
  }
}
