import Foundation
import Security

struct SavedProject: Codable, Equatable, Identifiable {
  var id: String
  var name: String
  var directory: String
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
  var projects: [SavedProject]
  var selectedProjectID: String?

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
    projects: [],
    selectedProjectID: nil
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
