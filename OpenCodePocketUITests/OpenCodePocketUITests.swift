import XCTest

final class OpenCodePocketUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  private func makeWorkspaceApp() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing-workspace"]
    app.launchEnvironment["OPENCODE_POCKET_UI_TEST_WORKSPACE"] = "1"
    return app
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
    let app = makeWorkspaceApp()
    app.launch()

    let anyElements = app.descendants(matching: .any)

    XCTAssertTrue(
      anyElements["workspace.session.pane"].waitForExistence(timeout: 15),
      "Expected workspace session pane after bootstrap"
    )

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
    XCTAssertTrue(anyElements["workspace.drawer"].waitForExistence(timeout: 4), "Expected drawer sheet")
    XCTAssertTrue(app.buttons["drawer.refresh"].exists, "Expected drawer refresh action")
    XCTAssertTrue(app.buttons["drawer.create"].exists, "Expected drawer create action")
    XCTAssertTrue(app.buttons["drawer.project.add"].exists, "Expected drawer add project action")

    let projectButton = app.buttons
      .matching(NSPredicate(format: "identifier BEGINSWITH %@", "drawer.project."))
      .firstMatch
    XCTAssertTrue(projectButton.exists, "Expected at least one project selector in drawer")

    let sessionRow = app.buttons["drawer.session.ses_mock_primary"]
    XCTAssertTrue(sessionRow.waitForExistence(timeout: 4), "Expected selectable mock session row")
    sessionRow.tap()

    XCTAssertTrue(anyElements["composer.agentMenu"].waitForExistence(timeout: 4), "Expected agent menu in composer")
    XCTAssertTrue(anyElements["composer.modelMenu"].exists, "Expected model menu in composer")
    XCTAssertTrue(anyElements["composer.effortMenu"].exists, "Expected thinking effort menu in composer")
    XCTAssertTrue(anyElements["composer.sendAbort"].exists, "Expected send/abort control in composer")
  }

  @MainActor
  func testTranscriptReasoningToggleAndMessageCopyContracts() throws {
    let app = makeWorkspaceApp()
    app.launch()

    let actionsMenu = app.buttons["workspace.actions.menu"].firstMatch
    XCTAssertTrue(actionsMenu.waitForExistence(timeout: 10), "Expected actions menu in workspace toolbar")
    actionsMenu.tap()

    let reasoningItem = app.buttons["Show Reasoning Summaries"]
    XCTAssertTrue(reasoningItem.waitForExistence(timeout: 4), "Expected reasoning summaries toggle in actions menu")
    reasoningItem.tap()

    let reasoningItemSecondPass = app.buttons["Show Reasoning Summaries"]
    if !reasoningItemSecondPass.exists {
      actionsMenu.tap()
    }
    XCTAssertTrue(reasoningItemSecondPass.waitForExistence(timeout: 4), "Expected reasoning summaries toggle after reopening actions menu")
    reasoningItemSecondPass.tap()

    let composerInput = app.descendants(matching: .any)["composer.input"]
    XCTAssertTrue(composerInput.waitForExistence(timeout: 4), "Expected composer input")
    composerInput.tap()
    composerInput.typeText("Contract coverage message")

    let sendAbort = app.buttons["composer.sendAbort"]
    XCTAssertTrue(sendAbort.exists, "Expected send/abort composer control")
    sendAbort.tap()

    let copyButton = app.buttons["message.assistant.copy"].firstMatch
    XCTAssertTrue(copyButton.waitForExistence(timeout: 6), "Expected assistant copy control in transcript")

    let userCopyButton = app.buttons
      .matching(NSPredicate(format: "identifier BEGINSWITH %@", "message.user.copy."))
      .firstMatch
    XCTAssertTrue(userCopyButton.waitForExistence(timeout: 6), "Expected user copy control in transcript")

  }

  @MainActor
  func testTranscriptMarkdownFixtureContracts() throws {
    let app = makeWorkspaceApp()
    app.launch()

    XCTAssertTrue(
      app.staticTexts["From our best current science, here is the short version:"].waitForExistence(timeout: 10),
      "Expected markdown fixture heading in transcript"
    )

    XCTAssertTrue(
      app.staticTexts["About 13.8 billion years ago, the universe began in a hot, dense state (the Big Bang)."]
        .waitForExistence(timeout: 4),
      "Expected rendered bullet-list item in transcript"
    )

    XCTAssertTrue(
      app.staticTexts["print(\"hello cosmos\")"].waitForExistence(timeout: 4),
      "Expected rendered code block content in transcript"
    )

    let swiftLink = app.links["Swift.org"]
    let swiftText = app.staticTexts["Swift.org"]
    XCTAssertTrue(
      swiftLink.waitForExistence(timeout: 3) || swiftText.waitForExistence(timeout: 1),
      "Expected markdown link label to be visible"
    )
  }
}
