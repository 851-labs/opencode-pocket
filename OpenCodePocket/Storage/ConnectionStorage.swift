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
    baseURL: String,
    username: String,
    useBasicAuth: Bool,
    directory: String,
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
    self.baseURL = baseURL
    self.username = username
    self.useBasicAuth = useBasicAuth
    self.directory = directory
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

  private enum CodingKeys: String, CodingKey {
    case baseURL
    case username
    case useBasicAuth
    case directory
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

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    baseURL = try container.decodeIfPresent(String.self, forKey: .baseURL) ?? Self.default.baseURL
    username = try container.decodeIfPresent(String.self, forKey: .username) ?? Self.default.username
    useBasicAuth = try container.decodeIfPresent(Bool.self, forKey: .useBasicAuth) ?? Self.default.useBasicAuth
    directory = try container.decodeIfPresent(String.self, forKey: .directory) ?? Self.default.directory
    selectedAgent = try container.decodeIfPresent(String.self, forKey: .selectedAgent)
    selectedProviderID = try container.decodeIfPresent(String.self, forKey: .selectedProviderID)
    selectedModelID = try container.decodeIfPresent(String.self, forKey: .selectedModelID)
    selectedModelVariant = try container.decodeIfPresent(String.self, forKey: .selectedModelVariant)
    hiddenModelKeys = try container.decodeIfPresent([String].self, forKey: .hiddenModelKeys) ?? Self.default.hiddenModelKeys
    pinnedSessionIDs = try container.decodeIfPresent([String].self, forKey: .pinnedSessionIDs) ?? Self.default.pinnedSessionIDs
    projects = try container.decodeIfPresent([SavedProject].self, forKey: .projects) ?? Self.default.projects
    selectedProjectID = try container.decodeIfPresent(String.self, forKey: .selectedProjectID)
    showReasoningSummaries =
      try container.decodeIfPresent(Bool.self, forKey: .showReasoningSummaries) ?? Self.default.showReasoningSummaries
    expandShellToolParts =
      try container.decodeIfPresent(Bool.self, forKey: .expandShellToolParts) ?? Self.default.expandShellToolParts
    expandEditToolParts =
      try container.decodeIfPresent(Bool.self, forKey: .expandEditToolParts) ?? Self.default.expandEditToolParts
    notifyAgentSystemNotifications =
      try container.decodeIfPresent(Bool.self, forKey: .notifyAgentSystemNotifications)
        ?? Self.default.notifyAgentSystemNotifications
    notifyPermissionSystemNotifications =
      try container.decodeIfPresent(Bool.self, forKey: .notifyPermissionSystemNotifications)
        ?? Self.default.notifyPermissionSystemNotifications
    notifyErrorSystemNotifications =
      try container.decodeIfPresent(Bool.self, forKey: .notifyErrorSystemNotifications)
        ?? Self.default.notifyErrorSystemNotifications
  }

  static let `default` = ConnectionSettings(
    baseURL: "http://claudl.taile64ce5.ts.net:4096",
    username: "opencode",
    useBasicAuth: false,
    directory: "",
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
