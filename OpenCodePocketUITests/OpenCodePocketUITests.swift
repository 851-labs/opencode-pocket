import XCTest

final class OpenCodePocketUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testConnectScreenAndServerAttempt() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing"]
    app.launch()

    let baseURLField = app.textFields["connect.baseURL"]
    XCTAssertTrue(baseURLField.waitForExistence(timeout: 10), "Expected base URL field on connect screen")

    let useBasicAuthToggle = app.switches["connect.useBasicAuth"]
    XCTAssertTrue(useBasicAuthToggle.waitForExistence(timeout: 5), "Expected basic auth toggle")
    useBasicAuthToggle.tap()
    useBasicAuthToggle.tap()

    let connectButton = app.buttons["connect.button"]
    XCTAssertTrue(connectButton.exists, "Expected connect button")
    connectButton.tap()

    sleep(3)
    XCTAssertEqual(app.state, .runningForeground, "Expected app to remain in foreground after connect attempt")
  }

  @MainActor
  func testWorkspaceToolbarDrawerAndComposer() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing-workspace"]
    app.launchEnvironment["OPENCODE_POCKET_UI_TEST_WORKSPACE"] = "1"
    app.launch()

    let anyElements = app.descendants(matching: .any)

    let drawerToggle = app.buttons["workspace.drawer.toggle"].firstMatch
    XCTAssertTrue(drawerToggle.waitForExistence(timeout: 15), "Expected drawer toggle in workspace toolbar")

    let panelPicker = anyElements["workspace.panel.picker"]
    XCTAssertTrue(panelPicker.exists, "Expected panel picker in workspace toolbar")

    let changesButton = app.buttons["Changes"]
    XCTAssertTrue(changesButton.exists, "Expected changes panel segment")
    changesButton.tap()

    let diffFileLabel = app.staticTexts["OpenCodePocket/App/AppStore.swift"]
    let emptyChangesTitle = app.staticTexts["No Code Changes"]
    let hasChangesPane = diffFileLabel.waitForExistence(timeout: 4) || emptyChangesTitle.waitForExistence(timeout: 1)
    XCTAssertTrue(hasChangesPane, "Expected changes pane after switching panels")

    drawerToggle.tap()
    let sessionRow = app.buttons["drawer.session.ses_mock_secondary"]
    XCTAssertTrue(sessionRow.waitForExistence(timeout: 4), "Expected selectable mock session row")
    sessionRow.tap()

    XCTAssertTrue(anyElements["composer.agentMenu"].waitForExistence(timeout: 4), "Expected agent menu in composer")
    XCTAssertTrue(anyElements["composer.modelMenu"].exists, "Expected model menu in composer")
    XCTAssertTrue(anyElements["composer.sendAbort"].exists, "Expected send/abort control in composer")
  }
}
