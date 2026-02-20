@testable import OpenCodePocket
import XCTest

final class RequestBuilderTests: XCTestCase {
  func testBuildsGETRequestWithQueryAndAuth() throws {
    let builder = HTTPRequestBuilder(
      baseURL: URL(string: "http://example.com:4096")!,
      username: "opencode",
      password: "secret"
    )

    let request = try builder.makeRequest(
      path: "/session",
      method: .get,
      query: [URLQueryItem(name: "directory", value: "/tmp/project")]
    )

    XCTAssertEqual(request.httpMethod, "GET")
    XCTAssertEqual(request.url?.absoluteString, "http://example.com:4096/session?directory=/tmp/project")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Basic b3BlbmNvZGU6c2VjcmV0")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
  }

  func testBuildsPOSTRequestWithBody() throws {
    let builder = HTTPRequestBuilder(
      baseURL: URL(string: "http://localhost:4096")!,
      username: nil,
      password: nil
    )

    let request = try builder.makeRequest(
      path: "/session",
      method: .post,
      body: Data("{}".utf8)
    )

    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    XCTAssertEqual(request.httpBody, Data("{}".utf8))
  }
}
