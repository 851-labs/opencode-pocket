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
}
