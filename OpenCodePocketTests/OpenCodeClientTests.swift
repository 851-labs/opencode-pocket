import Foundation
import OpenCodeModels
import OpenCodeNetworking
import XCTest

final class OpenCodeClientTests: XCTestCase {
  override func setUp() {
    super.setUp()
    URLProtocolStub.reset()
  }

  override func tearDown() {
    URLProtocolStub.reset()
    super.tearDown()
  }

  func testEndpointsAndSuccessPaths() async throws {
    URLProtocolStub.handler = { request in
      switch (request.httpMethod, request.url?.path) {
      case ("GET", "/global/health"):
        return try makeJSONResponse(request: request, json: """
        {"healthy":true,"version":"1.2.3"}
        """)
      case ("GET", "/session"):
        return try makeJSONResponse(request: request, json: """
        [{"id":"ses_1","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Session","version":"1","time":{"created":1,"updated":2,"archived":null},"summary":null,"share":null,"revert":null}]
        """)
      case ("GET", "/agent"):
        return try makeJSONResponse(request: request, json: """
        [{"name":"build","description":"Build agent","mode":"primary","hidden":false}]
        """)
      case ("GET", "/config/providers"):
        return try makeJSONResponse(request: request, json: """
        {"providers":[{"id":"openai","name":"OpenAI","models":{"gpt-5":{"id":"gpt-5","providerID":"openai","name":"GPT-5","variants":{"high":{}}}}}],"default":{"openai":"gpt-5"}}
        """)
      case ("POST", "/session"):
        return try makeJSONResponse(request: request, json: """
        {"id":"ses_new","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Created","version":"1","time":{"created":1,"updated":1,"archived":null},"summary":null,"share":null,"revert":null}
        """)
      case ("GET", let path) where path?.contains("/message/") == true:
        return try makeJSONResponse(request: request, json: Self.messageJSON(id: "msg_get", sessionID: "ses_1", text: "hello"))
      case ("GET", let path) where path?.hasSuffix("/message") == true:
        return try makeJSONResponse(request: request, json: "[\(Self.messageJSON(id: "msg_list", sessionID: "ses_1", text: "listed"))]")
      case ("GET", let path) where path?.hasSuffix("/diff") == true:
        return try makeJSONResponse(request: request, json: "[{\"file\":\"a.swift\",\"before\":\"\",\"after\":\"\",\"additions\":2,\"deletions\":1,\"status\":\"modified\"}]")
      case ("GET", let path) where path?.hasPrefix("/session/") == true:
        return try makeJSONResponse(request: request, json: """
        {"id":"ses_get","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Fetched","version":"1","time":{"created":1,"updated":1,"archived":null},"summary":null,"share":null,"revert":null}
        """)
      case ("PATCH", let path) where path?.hasPrefix("/session/") == true:
        return try makeJSONResponse(request: request, json: """
        {"id":"ses_patch","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Patched","version":"1","time":{"created":1,"updated":2,"archived":null},"summary":null,"share":null,"revert":null}
        """)
      case ("DELETE", let path) where path?.hasPrefix("/session/") == true:
        return try makeJSONResponse(request: request, json: "true")
      case ("POST", let path) where path?.hasSuffix("/message") == true:
        return try makeJSONResponse(request: request, json: Self.messageJSON(id: "msg_send", sessionID: "ses_1", text: "sent"))
      case ("POST", let path) where path?.hasSuffix("/prompt_async") == true:
        return try makeJSONResponse(request: request, json: "{}")
      case ("POST", let path) where path?.hasSuffix("/abort") == true:
        return try makeJSONResponse(request: request, json: "true")
      case ("GET", "/permission"):
        return try makeJSONResponse(request: request, json: "[{\"id\":\"perm_1\",\"sessionID\":\"ses_1\",\"permission\":\"bash\",\"patterns\":[\"src/**\"],\"metadata\":{},\"always\":[],\"tool\":{\"messageID\":\"msg_1\",\"callID\":\"call_1\"}}]")
      case ("POST", let path) where path?.hasPrefix("/permission/") == true && path?.hasSuffix("/reply") == true:
        return try makeJSONResponse(request: request, json: "true")
      case ("GET", "/question"):
        return try makeJSONResponse(request: request, json: "[{\"id\":\"q_1\",\"sessionID\":\"ses_1\",\"questions\":[{\"question\":\"Pick one\",\"header\":\"Confirm\",\"options\":[{\"label\":\"Yes\",\"description\":\"Proceed\"}],\"multiple\":false}],\"tool\":{\"messageID\":\"msg_1\",\"callID\":\"call_2\"}}]")
      case ("POST", let path) where path?.hasPrefix("/question/") == true && path?.hasSuffix("/reply") == true:
        return try makeJSONResponse(request: request, json: "true")
      case ("POST", let path) where path?.hasPrefix("/question/") == true && path?.hasSuffix("/reject") == true:
        return try makeJSONResponse(request: request, json: "true")
      default:
        XCTFail("Unexpected request: \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "nil")")
        return try makeStatusResponse(request: request, code: 500, body: Data())
      }
    }

    let client = makeClient(directory: "/tmp/default")

    let health = try await client.health()
    XCTAssertTrue(health.healthy)
    XCTAssertEqual(health.version, "1.2.3")

    let sessions = try await client.listSessions()
    XCTAssertEqual(sessions.count, 1)

    let agents = try await client.listAgents()
    XCTAssertEqual(agents.first?.name, "build")

    let providers = try await client.listConfigProviders()
    XCTAssertEqual(providers.providers.first?.id, "openai")

    let created = try await client.createSession(SessionCreateRequest(title: "Hi"))
    XCTAssertEqual(created.id, "ses_new")

    let fetched = try await client.getSession(id: "ses 1")
    XCTAssertEqual(fetched.id, "ses_get")

    let updated = try await client.updateSession(id: "ses 1", body: SessionUpdateRequest(title: "Renamed"))
    XCTAssertEqual(updated.id, "ses_patch")

    let deleted = try await client.deleteSession(id: "ses_1")
    XCTAssertTrue(deleted)

    let listedMessages = try await client.listMessages(sessionID: "ses_1", limit: 5)
    XCTAssertEqual(listedMessages.first?.id, "msg_list")

    let fetchedMessage = try await client.getMessage(sessionID: "ses_1", messageID: "msg_1")
    XCTAssertEqual(fetchedMessage.id, "msg_get")

    let diffs = try await client.getSessionDiff(sessionID: "ses_1", messageID: "msg_1")
    XCTAssertEqual(diffs.first?.file, "a.swift")

    let sent = try await client.sendMessage(sessionID: "ses_1", body: PromptRequest(parts: [.text("Hello")]))
    XCTAssertEqual(sent.id, "msg_send")

    try await client.sendMessageAsync(sessionID: "ses_1", body: PromptRequest(parts: [.text("async")]))

    let aborted = try await client.abortSession(sessionID: "ses_1")
    XCTAssertTrue(aborted)

    let permissions = try await client.listPermissions()
    XCTAssertEqual(permissions.first?.id, "perm_1")

    let permissionReply = try await client.replyPermission(requestID: "perm_1", reply: .once)
    XCTAssertTrue(permissionReply)

    let questions = try await client.listQuestions()
    XCTAssertEqual(questions.first?.id, "q_1")

    let questionReply = try await client.replyQuestion(requestID: "q_1", answers: [["Yes"]])
    XCTAssertTrue(questionReply)

    let questionReject = try await client.rejectQuestion(requestID: "q_1")
    XCTAssertTrue(questionReject)

    let requests = URLProtocolStub.recordedRequests
    XCTAssertTrue(requests.contains { $0.url?.path == "/session" && $0.httpMethod == "GET" })
    XCTAssertTrue(requests.contains { $0.url?.path == "/session" && $0.url?.query?.contains("directory=/tmp/default") == true })
    XCTAssertTrue(requests.contains { $0.url?.path.contains("/session/ses") == true && $0.httpMethod == "GET" })
    XCTAssertTrue(requests.contains { $0.url?.absoluteString.contains("limit=5") == true })
    XCTAssertTrue(requests.contains { $0.url?.absoluteString.contains("messageID=msg_1") == true })
    XCTAssertTrue(requests.contains { $0.url?.path == "/permission" && $0.httpMethod == "GET" })
    XCTAssertTrue(requests.contains { $0.url?.path == "/permission/perm_1/reply" && $0.httpMethod == "POST" })
    XCTAssertTrue(requests.contains { $0.url?.path == "/question" && $0.httpMethod == "GET" })
    XCTAssertTrue(requests.contains { $0.url?.path == "/question/q_1/reply" && $0.httpMethod == "POST" })
    XCTAssertTrue(requests.contains { $0.url?.path == "/question/q_1/reject" && $0.httpMethod == "POST" })
  }

  func testDirectoryQueryOverride() async throws {
    URLProtocolStub.handler = { request in
      XCTAssertEqual(request.url?.path, "/session")
      XCTAssertEqual(request.url?.query, "directory=/tmp/override")
      return try makeJSONResponse(request: request, json: "[]")
    }

    let client = makeClient(directory: "/tmp/default")
    _ = try await client.listSessions(directory: "/tmp/override")
  }

  func testNoDirectoryQueryWhenUnset() async throws {
    URLProtocolStub.handler = { request in
      XCTAssertNil(request.url?.query)
      return try makeJSONResponse(request: request, json: "[]")
    }

    let client = makeClient(directory: nil)
    _ = try await client.listSessions()
  }

  func testRequestFailsWithInvalidResponse() async {
    URLProtocolStub.handler = { request in
      let response = URLResponse(url: try XCTUnwrap(request.url), mimeType: "application/json", expectedContentLength: 2, textEncodingName: nil)
      return (response, Data("{}".utf8))
    }

    let client = makeClient()
    await assertClientError(try await client.health(), expected: .invalidResponse)
  }

  func testRequestWrapsTransportError() async {
    URLProtocolStub.handler = { _ in
      throw URLError(.timedOut)
    }

    let client = makeClient()
    await assertClientError(try await client.health(), expected: .transport)
  }

  func testRequestThrowsDecodingError() async {
    URLProtocolStub.handler = { request in
      try makeJSONResponse(request: request, json: "{\"healthy\":\"oops\"}")
    }

    let client = makeClient()
    await assertClientError(try await client.health(), expected: .decoding)
  }

  func testParsesNotFoundEnvelopeError() async {
    URLProtocolStub.handler = { request in
      try makeStatusResponse(
        request: request,
        code: 404,
        body: Data("{\"name\":\"NotFoundError\",\"data\":{\"message\":\"Missing\"}}".utf8)
      )
    }

    let client = makeClient()
    await assertHTTPStatusError(try await client.health(), code: 404, contains: "Missing")
  }

  func testParsesBadRequestErrorArrayEnvelope() async {
    URLProtocolStub.handler = { request in
      try makeStatusResponse(
        request: request,
        code: 400,
        body: Data("{\"errors\":[{\"message\":\"Bad input\"}],\"success\":false}".utf8)
      )
    }

    let client = makeClient()
    await assertHTTPStatusError(try await client.health(), code: 400, contains: "Bad input")
  }

  func testParsesBadRequestDataEnvelope() async {
    URLProtocolStub.handler = { request in
      try makeStatusResponse(
        request: request,
        code: 400,
        body: Data("{\"data\":{\"message\":\"Data error\"},\"success\":false}".utf8)
      )
    }

    let client = makeClient()
    await assertHTTPStatusError(try await client.health(), code: 400, contains: "Data error")
  }

  func testParsesRawBodyError() async {
    URLProtocolStub.handler = { request in
      try makeStatusResponse(request: request, code: 500, body: Data("boom".utf8))
    }

    let client = makeClient()
    await assertHTTPStatusError(try await client.health(), code: 500, contains: "boom")
  }

  func testParsesEmptyBodyError() async {
    URLProtocolStub.handler = { request in
      try makeStatusResponse(request: request, code: 500, body: Data())
    }

    let client = makeClient()
    await assertHTTPStatusError(try await client.health(), code: 500, contains: nil)
  }

  func testRequestNoContentPathWrapsTransportError() async {
    URLProtocolStub.handler = { _ in
      throw URLError(.cannotConnectToHost)
    }

    let client = makeClient()
    await assertClientError(
      try await client.sendMessageAsync(sessionID: "ses_1", body: PromptRequest(parts: [.text("x")])),
      expected: .transport
    )
  }

  func testRequestNoContentPathParsesStatusError() async {
    URLProtocolStub.handler = { request in
      try makeStatusResponse(
        request: request,
        code: 400,
        body: Data("{\"errors\":[{\"message\":\"No content failed\"}],\"success\":false}".utf8)
      )
    }

    let client = makeClient()
    await assertHTTPStatusError(
      try await client.sendMessageAsync(sessionID: "ses_1", body: PromptRequest(parts: [.text("x")])),
      code: 400,
      contains: "No content failed"
    )
  }

  func testRequestNoContentPathFailsWithInvalidResponse() async {
    URLProtocolStub.handler = { request in
      let response = URLResponse(url: try XCTUnwrap(request.url), mimeType: "application/json", expectedContentLength: 0, textEncodingName: nil)
      return (response, Data())
    }

    let client = makeClient()
    await assertClientError(
      try await client.sendMessageAsync(sessionID: "ses_1", body: PromptRequest(parts: [.text("x")])),
      expected: .invalidResponse
    )
  }

  func testEncodeBodyFailureReturnsMessageError() async {
    URLProtocolStub.handler = { request in
      try makeJSONResponse(request: request, json: "{}")
    }

    let client = makeClient()
    await assertClientError(
      try await client.updateSession(
        id: "ses_1",
        body: SessionUpdateRequest(time: SessionUpdateTime(archived: .nan))
      ),
      expected: .message
    )
  }

  func testSubscribeEventsParsesStreamReconnectsAndSendsLastEventID() async {
    let lock = NSLock()
    var attempts = 0

    URLProtocolStub.handler = { request in
      lock.lock()
      attempts += 1
      let currentAttempt = attempts
      lock.unlock()

      switch currentAttempt {
      case 1:
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "text/event-stream")
        XCTAssertNil(request.value(forHTTPHeaderField: "Last-Event-ID"))
        return try makeStatusResponse(
          request: request,
          code: 200,
          body: Data("id: evt-1\nretry: 1\ndata: {\"type\":\"server.connected\",\"properties\":{}}\n\ndata: not-json\n\n".utf8)
        )
      case 2:
        XCTAssertEqual(request.value(forHTTPHeaderField: "Last-Event-ID"), "evt-1")
        let response = URLResponse(
          url: try XCTUnwrap(request.url),
          mimeType: "text/event-stream",
          expectedContentLength: 0,
          textEncodingName: nil
        )
        return (response, Data())
      case 3:
        XCTAssertEqual(request.value(forHTTPHeaderField: "Last-Event-ID"), "evt-1")
        return try makeStatusResponse(request: request, code: 503, body: Data())
      default:
        XCTAssertEqual(request.value(forHTTPHeaderField: "Last-Event-ID"), "evt-1")
        return try makeStatusResponse(
          request: request,
          code: 200,
          body: Data("data: {\"type\":\"server.heartbeat\",\"properties\":{}}\n\n".utf8)
        )
      }
    }

    let client = makeClient()
    let stream = client.subscribeEvents()

    var received: [ServerEvent] = []
    for await event in stream {
      received.append(event)
      if received.count == 3 {
        break
      }
    }

    XCTAssertEqual(received.map(\.type), ["server.connected", "event.decode.error", "server.heartbeat"])
    XCTAssertGreaterThanOrEqual(URLProtocolStub.recordedRequests.count, 4)
  }

  func testErrorDescriptions() {
    XCTAssertEqual(OpenCodeClientError.invalidURL("x").errorDescription, "Invalid server URL: x")
    XCTAssertEqual(OpenCodeClientError.invalidResponse.errorDescription, "Server returned an invalid response.")
    XCTAssertTrue(OpenCodeClientError.transport(URLError(.timedOut)).errorDescription?.contains("Network error") == true)
    XCTAssertTrue(OpenCodeClientError.decoding(NSError(domain: "test", code: 1)).errorDescription?.contains("Failed to decode") == true)
    XCTAssertEqual(OpenCodeClientError.httpStatus(code: 500, message: "boom").errorDescription, "Server error (500): boom")
    XCTAssertEqual(OpenCodeClientError.message("custom").errorDescription, "custom")
  }

  private func makeClient(directory: String? = "/tmp/default") -> OpenCodeClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolStub.self]
    let session = URLSession(configuration: config)

    return OpenCodeClient(
      configuration: OpenCodeClientConfiguration(
        baseURL: URL(string: "http://localhost:4096")!,
        username: "opencode",
        password: "secret",
        directory: directory
      ),
      urlSession: session
    )
  }

  private func assertClientError<T>(_ operation: @autoclosure () async throws -> T, expected: ErrorKind) async {
    do {
      _ = try await operation()
      XCTFail("Expected error")
    } catch let error as OpenCodeClientError {
      switch (expected, error) {
      case (.invalidResponse, .invalidResponse),
           (.transport, .transport),
           (.decoding, .decoding),
           (.message, .message):
        return
      default:
        XCTFail("Unexpected error: \(error)")
      }
    } catch {
      XCTFail("Unexpected non-client error: \(error)")
    }
  }

  private func assertHTTPStatusError<T>(_ operation: @autoclosure () async throws -> T, code: Int, contains fragment: String?) async {
    do {
      _ = try await operation()
      XCTFail("Expected HTTP status error")
    } catch let error as OpenCodeClientError {
      guard case let .httpStatus(statusCode, message) = error else {
        XCTFail("Unexpected error: \(error)")
        return
      }
      XCTAssertEqual(statusCode, code)
      if let fragment {
        XCTAssertTrue(message?.contains(fragment) == true)
      } else {
        XCTAssertNil(message)
      }
    } catch {
      XCTFail("Unexpected non-client error: \(error)")
    }
  }
}

private enum ErrorKind {
  case invalidResponse
  case transport
  case decoding
  case message
}

private final class URLProtocolStub: URLProtocol {
  static var handler: ((URLRequest) throws -> (URLResponse, Data))?

  private static let lock = NSLock()
  private static var requests: [URLRequest] = []

  static var recordedRequests: [URLRequest] {
    lock.lock()
    defer { lock.unlock() }
    return requests
  }

  static func reset() {
    lock.lock()
    handler = nil
    requests.removeAll()
    lock.unlock()
  }

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let handler = Self.handler else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    Self.lock.lock()
    Self.requests.append(request)
    Self.lock.unlock()

    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      if !data.isEmpty {
        client?.urlProtocol(self, didLoad: data)
      }
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}

private func makeStatusResponse(request: URLRequest, code: Int, body: Data) throws -> (URLResponse, Data) {
  let url = try XCTUnwrap(request.url)
  let response = try XCTUnwrap(
    HTTPURLResponse(url: url, statusCode: code, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])
  )
  return (response, body)
}

private func makeJSONResponse(request: URLRequest, json: String) throws -> (URLResponse, Data) {
  try makeStatusResponse(request: request, code: 200, body: Data(json.utf8))
}

private extension OpenCodeClientTests {
  static func messageJSON(id: String, sessionID: String, text: String) -> String {
    """
    {
      "info": {
        "id": "\(id)",
        "sessionID": "\(sessionID)",
        "role": "assistant",
        "agent": "build"
      },
      "parts": [
        {
          "id": "prt_\(id)",
          "sessionID": "\(sessionID)",
          "messageID": "\(id)",
          "type": "text",
          "text": "\(text)"
        }
      ]
    }
    """
  }
}
