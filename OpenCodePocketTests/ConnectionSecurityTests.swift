import Foundation
import XCTest
@testable import OpenCodePocket

final class ConnectionSecurityTests: XCTestCase {
  @MainActor
  func testPersistSettingsStoresPasswordInKeychainNotUserDefaults() {
    let (settingsStore, defaults, suiteName) = makeSettingsStore()
    let username = "security-user"
    let secret = "secret-\(UUID().uuidString)"
    let baseURL = "https://security.example"

    defer {
      settingsStore.deletePassword(baseURL: baseURL, username: username)
      defaults.removePersistentDomain(forName: suiteName)
    }

    let connection = ConnectionStore(settingsStore: settingsStore)
    connection.baseURL = baseURL
    connection.username = username
    connection.password = secret
    connection.useBasicAuth = true

    persist(connection)

    let normalizedBaseURL = settingsStore.loadSettings().baseURL
    XCTAssertEqual(settingsStore.loadPassword(baseURL: normalizedBaseURL, username: username), secret)

    let secretData = Data(secret.utf8)
    let leakedInUserDefaults = defaults.dictionaryRepresentation().values
      .compactMap { $0 as? Data }
      .contains { data in
        data.range(of: secretData) != nil
      }
    XCTAssertFalse(leakedInUserDefaults, "Expected plaintext password to stay out of defaults payload")
  }

  @MainActor
  func testPersistSettingsDeletesPasswordWhenBasicAuthDisabled() {
    let (settingsStore, defaults, suiteName) = makeSettingsStore()
    let username = "security-user"
    let baseURL = "https://security.example"

    defer {
      settingsStore.deletePassword(baseURL: baseURL, username: username)
      defaults.removePersistentDomain(forName: suiteName)
    }

    let connection = ConnectionStore(settingsStore: settingsStore)
    connection.baseURL = baseURL
    connection.username = username
    connection.password = "enabled-secret"
    connection.useBasicAuth = true
    persist(connection)

    let normalizedBaseURL = settingsStore.loadSettings().baseURL
    XCTAssertEqual(settingsStore.loadPassword(baseURL: normalizedBaseURL, username: username), "enabled-secret")

    connection.useBasicAuth = false
    persist(connection)

    XCTAssertNil(settingsStore.loadPassword(baseURL: normalizedBaseURL, username: username))
  }

  @MainActor
  func testPersistSettingsDeletesOldCredentialWhenUsernameChanges() {
    let (settingsStore, defaults, suiteName) = makeSettingsStore()
    let oldUsername = "security-old"
    let newUsername = "security-new"
    let baseURL = "https://security.example"

    defer {
      settingsStore.deletePassword(baseURL: baseURL, username: oldUsername)
      settingsStore.deletePassword(baseURL: baseURL, username: newUsername)
      defaults.removePersistentDomain(forName: suiteName)
    }

    let connection = ConnectionStore(settingsStore: settingsStore)
    connection.baseURL = baseURL
    connection.username = oldUsername
    connection.password = "old-secret"
    connection.useBasicAuth = true
    persist(connection)

    let normalizedBaseURL = settingsStore.loadSettings().baseURL
    XCTAssertEqual(settingsStore.loadPassword(baseURL: normalizedBaseURL, username: oldUsername), "old-secret")

    connection.username = newUsername
    connection.password = "new-secret"
    persist(connection)

    XCTAssertNil(settingsStore.loadPassword(baseURL: normalizedBaseURL, username: oldUsername))
    XCTAssertEqual(settingsStore.loadPassword(baseURL: normalizedBaseURL, username: newUsername), "new-secret")
  }

  @MainActor
  func testPersistSettingsDeletesOldCredentialWhenBaseURLChanges() {
    let (settingsStore, defaults, suiteName) = makeSettingsStore()
    let username = "security-user"
    let initialBaseURL = "https://security-one.example"
    let nextBaseURL = "https://security-two.example"

    defer {
      settingsStore.deletePassword(baseURL: initialBaseURL, username: username)
      settingsStore.deletePassword(baseURL: nextBaseURL, username: username)
      defaults.removePersistentDomain(forName: suiteName)
    }

    let connection = ConnectionStore(settingsStore: settingsStore)
    connection.baseURL = initialBaseURL
    connection.username = username
    connection.password = "first-secret"
    connection.useBasicAuth = true
    persist(connection)

    let savedInitialBaseURL = settingsStore.loadSettings().baseURL
    XCTAssertEqual(settingsStore.loadPassword(baseURL: savedInitialBaseURL, username: username), "first-secret")

    connection.baseURL = nextBaseURL
    connection.password = "second-secret"
    persist(connection)

    let savedNextBaseURL = settingsStore.loadSettings().baseURL
    XCTAssertNil(settingsStore.loadPassword(baseURL: savedInitialBaseURL, username: username))
    XCTAssertEqual(settingsStore.loadPassword(baseURL: savedNextBaseURL, username: username), "second-secret")
  }

  @MainActor
  private func persist(_ connection: ConnectionStore) {
    connection.persistSettingsBestEffort(
      selectedAgentName: "build",
      selectedModel: nil,
      selectedModelVariant: nil,
      hiddenModelKeys: [],
      projects: [],
      selectedProjectID: nil
    )
  }

  private func makeSettingsStore() -> (ConnectionSettingsStore, UserDefaults, String) {
    let suiteName = "ConnectionSecurityTests.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
      fatalError("Expected isolated defaults suite")
    }
    defaults.removePersistentDomain(forName: suiteName)
    return (ConnectionSettingsStore(defaults: defaults), defaults, suiteName)
  }
}
