import Foundation
import OpenCodeNetworking
import XCTest

final class LiveServerIntegrationTests: XCTestCase {
  func testHealthAndSessionListAgainstLiveServer() async throws {
    let env = ProcessInfo.processInfo.environment

    guard env["OPENCODE_RUN_LIVE_TESTS"] == "1" else {
      throw XCTSkip("Skipping live tests because OPENCODE_RUN_LIVE_TESTS is not enabled")
    }

    if env["OPENCODE_SKIP_LIVE_TESTS"] == "1" {
      throw XCTSkip("Skipping live tests because OPENCODE_SKIP_LIVE_TESTS=1")
    }

    guard let baseURLString = env["OPENCODE_BASE_URL"], let baseURL = URL(string: baseURLString) else {
      throw XCTSkip("Skipping live tests because OPENCODE_BASE_URL is not configured")
    }

    let client = OpenCodeClient(
      configuration: OpenCodeClientConfiguration(
        baseURL: baseURL,
        username: env["OPENCODE_USERNAME"],
        password: env["OPENCODE_PASSWORD"],
        directory: env["OPENCODE_DIRECTORY"]
      )
    )

    let health = try await client.health()
    XCTAssertTrue(health.healthy)
    XCTAssertFalse(health.version.isEmpty)

    _ = try await client.listSessions()
  }
}
