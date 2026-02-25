import Foundation
@testable import OpenCodePocket
import XCTest

final class FeedSettingsPersistenceTests: XCTestCase {
  func testConnectionSettingsDecodesLegacyPayloadWithFeedDefaults() throws {
    let legacyJSON = """
    {
      "baseURL": "https://legacy.example",
      "username": "opencode",
      "useBasicAuth": false,
      "directory": "/tmp/project",
      "selectedAgent": "build",
      "selectedProviderID": null,
      "selectedModelID": null,
      "selectedModelVariant": null,
      "hiddenModelKeys": [],
      "projects": [],
      "selectedProjectID": null
    }
    """

    let data = try XCTUnwrap(legacyJSON.data(using: .utf8))
    let decoded = try JSONDecoder().decode(ConnectionSettings.self, from: data)

    XCTAssertFalse(decoded.showReasoningSummaries)
    XCTAssertTrue(decoded.expandShellToolParts)
    XCTAssertFalse(decoded.expandEditToolParts)
  }

  @MainActor
  func testWorkspacePersistsFeedSettingsWhenToggled() {
    let (settingsStore, defaults, suiteName) = makeSettingsStore()
    defer {
      defaults.removePersistentDomain(forName: suiteName)
    }

    let connection = ConnectionStore(settingsStore: settingsStore)
    let workspace = WorkspaceStore(connection: connection)

    workspace.showReasoningSummaries = true
    workspace.expandShellToolParts = false
    workspace.expandEditToolParts = true

    let persisted = settingsStore.loadSettings()
    XCTAssertTrue(persisted.showReasoningSummaries)
    XCTAssertFalse(persisted.expandShellToolParts)
    XCTAssertTrue(persisted.expandEditToolParts)
  }

  @MainActor
  func testWorkspaceLoadsPersistedFeedSettings() {
    let (settingsStore, defaults, suiteName) = makeSettingsStore()
    defer {
      defaults.removePersistentDomain(forName: suiteName)
    }

    var saved = ConnectionSettings.default
    saved.baseURL = "https://persisted.example"
    saved.showReasoningSummaries = true
    saved.expandShellToolParts = false
    saved.expandEditToolParts = true
    settingsStore.saveSettings(saved)

    let connection = ConnectionStore(settingsStore: settingsStore)
    let workspace = WorkspaceStore(connection: connection)

    XCTAssertTrue(workspace.showReasoningSummaries)
    XCTAssertFalse(workspace.expandShellToolParts)
    XCTAssertTrue(workspace.expandEditToolParts)
  }

  private func makeSettingsStore() -> (ConnectionSettingsStore, UserDefaults, String) {
    let suiteName = "FeedSettingsPersistenceTests.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
      fatalError("Expected isolated defaults suite")
    }
    defaults.removePersistentDomain(forName: suiteName)
    return (ConnectionSettingsStore(defaults: defaults), defaults, suiteName)
  }
}
