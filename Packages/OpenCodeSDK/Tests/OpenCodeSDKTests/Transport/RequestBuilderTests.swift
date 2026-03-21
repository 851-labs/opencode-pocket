import Foundation
import OpenCodeSDK
import Testing

@Suite(.tags(.networking))
struct RequestBuilderTests {
  @Test func buildsGETRequestWithQueryAndAuth() throws {
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

    #expect(request.httpMethod == "GET")
    #expect(request.url?.absoluteString == "http://example.com:4096/session?directory=/tmp/project")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Basic b3BlbmNvZGU6c2VjcmV0")
    #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
  }

  @Test func buildsPOSTRequestWithBody() throws {
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

    #expect(request.httpMethod == "POST")
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    #expect(request.httpBody == Data("{}".utf8))
  }

  @Test func customHeadersOverrideDefaults() throws {
    let builder = HTTPRequestBuilder(
      baseURL: URL(string: "http://localhost:4096")!,
      username: nil,
      password: nil
    )

    let request = try builder.makeRequest(
      path: "/event",
      method: .get,
      headers: [
        "Accept": "text/event-stream",
        "Last-Event-ID": "evt-42",
      ]
    )

    #expect(request.value(forHTTPHeaderField: "Accept") == "text/event-stream")
    #expect(request.value(forHTTPHeaderField: "Last-Event-ID") == "evt-42")
  }

  @Test func includesBasePathWhenPresent() throws {
    let builder = HTTPRequestBuilder(
      baseURL: URL(string: "http://localhost:4096/api")!,
      username: nil,
      password: nil
    )

    let request = try builder.makeRequest(path: "session", method: .get)
    #expect(request.url?.absoluteString == "http://localhost:4096/api/session")
  }

  @Test func buildsPUTRequest() throws {
    let builder = HTTPRequestBuilder(
      baseURL: URL(string: "http://localhost:4096")!,
      username: nil,
      password: nil
    )

    let request = try builder.makeRequest(path: "/session", method: .put)
    #expect(request.httpMethod == "PUT")
  }

  @Test func throwsForRelativeBaseURL() {
    let builder = HTTPRequestBuilder(
      baseURL: URL(string: "relative/base")!,
      username: nil,
      password: nil
    )

    let error = #expect(throws: OpenCodeClientError.self) {
      try builder.makeRequest(path: "/session", method: .get)
    }

    guard case let .invalidURL(value) = error else {
      Issue.record("Unexpected error: \(error)")
      return
    }

    #expect(value == "relative/base")
  }
}
