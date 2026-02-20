import Foundation
@testable import OpenCodePocket
import XCTest

final class LiveServerIntegrationTests: XCTestCase {
  func testHealthAndSessionListAgainstLiveServer() async throws {
    let env = ProcessInfo.processInfo.environment
    if env["OPENCODE_SKIP_LIVE_TESTS"] == "1" {
      throw XCTSkip("Skipping live tests because OPENCODE_SKIP_LIVE_TESTS=1")
    }

    let baseURLString = env["OPENCODE_BASE_URL"] ?? "http://claudl.taile64ce5.ts.net:4096"
    guard let baseURL = URL(string: baseURLString) else {
      XCTFail("Invalid OPENCODE_BASE_URL: \(baseURLString)")
      return
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
