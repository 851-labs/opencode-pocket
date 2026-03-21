import Foundation
import OpenCodeSDK
import Testing

@Suite(.tags(.networking, .live))
struct LiveServerIntegrationTests {
  @Test(.enabled(if: Self.shouldRunLiveTests), .timeLimit(.minutes(1)))
  func healthAndSessionListAgainstLiveServer() async throws {
    let env = Self.environment
    let baseURLString = try #require(env["OPENCODE_BASE_URL"])
    let baseURL = try #require(URL(string: baseURLString))

    let client = OpenCodeClient(
      configuration: OpenCodeClientConfiguration(
        baseURL: baseURL,
        username: env["OPENCODE_USERNAME"],
        password: env["OPENCODE_PASSWORD"],
        directory: env["OPENCODE_DIRECTORY"]
      )
    )

    let health = try await client.health()
    #expect(health.healthy == true)
    #expect(health.version.isEmpty == false)

    _ = try await client.listSessions()
  }
}

private extension LiveServerIntegrationTests {
  static var environment: [String: String] {
    ProcessInfo.processInfo.environment
  }

  static var shouldRunLiveTests: Bool {
    guard environment["OPENCODE_RUN_LIVE_TESTS"] == "1" else {
      return false
    }
    guard environment["OPENCODE_SKIP_LIVE_TESTS"] != "1" else {
      return false
    }
    guard let baseURLString = environment["OPENCODE_BASE_URL"] else {
      return false
    }
    return URL(string: baseURLString) != nil
  }
}
