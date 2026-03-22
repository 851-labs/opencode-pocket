import Foundation
import OpenCodeSDK
import Testing

struct OpenCodeClientRequestCoreTests {
  @Test func directoryQueryOverride() async throws {
    let controller = URLProtocolStubController { request in
      #expect(request.url?.path == "/session")
      #expect(request.url?.query == "directory=/tmp/override")
      return try makeJSONResponse(request: request, json: "[]")
    }

    let client = makeClient(controller: controller, directory: "/tmp/default")
    _ = try await client.listSessions(directory: "/tmp/override")
  }

  @Test func noDirectoryQueryWhenUnset() async throws {
    let controller = URLProtocolStubController { request in
      #expect(request.url?.query == nil)
      return try makeJSONResponse(request: request, json: "[]")
    }

    let client = makeClient(controller: controller, directory: nil)
    _ = try await client.listSessions()
  }

  @Test func whitespaceDirectoryQueryIsDropped() async throws {
    let controller = URLProtocolStubController { request in
      #expect(request.url?.query == nil)
      return try makeJSONResponse(request: request, json: "[]")
    }

    let client = makeClient(controller: controller, directory: nil)
    _ = try await client.listSessions(directory: "   ")
  }

  @Test func updateSessionSendsArchiveTimestampPayload() async throws {
    let controller = URLProtocolStubController { request in
      let body = try JSONSerialization.jsonObject(with: requestBodyData(request))
      let object = try requireDictionary(body)
      let time = try requireDictionary(object["time"])
      #expect(time["archived"] as? Double == 42)
      return try makeJSONResponse(request: request, json: """
      {"id":"ses_patch","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Patched","version":"1","time":{"created":1,"updated":2,"archived":42},"summary":null,"share":null,"revert":null}
      """)
    }

    let client = makeClient(controller: controller)
    _ = try await client.updateSession(id: "ses_1", body: SessionUpdateRequest(time: SessionUpdateTime(archived: 42)))
  }

  @Test func updateSessionSendsArchivedNullPayloadForUnarchive() async throws {
    let controller = URLProtocolStubController { request in
      let body = try JSONSerialization.jsonObject(with: requestBodyData(request))
      let object = try requireDictionary(body)
      let time = try requireDictionary(object["time"])
      #expect(time.keys.contains("archived"))
      #expect(time["archived"] is NSNull)
      return try makeJSONResponse(request: request, json: """
      {"id":"ses_patch","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Patched","version":"1","time":{"created":1,"updated":2,"archived":null},"summary":null,"share":null,"revert":null}
      """)
    }

    let client = makeClient(controller: controller)
    _ = try await client.updateSession(id: "ses_1", body: SessionUpdateRequest(time: .clearArchived()))
  }

  @Test func requestFailsWithInvalidResponse() async {
    let controller = URLProtocolStubController { _ in
      (URLResponse(), Data())
    }

    let client = makeClient(controller: controller)
    await assertClientError(expected: .invalidResponse) {
      try await client.health()
    }
  }

  @Test func requestWrapsTransportError() async {
    let controller = URLProtocolStubController { _ in
      throw URLError(.notConnectedToInternet)
    }

    let client = makeClient(controller: controller)
    await assertClientError(expected: .transport) {
      try await client.health()
    }
  }

  @Test func requestThrowsDecodingError() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(request: request, code: 200, body: Data("{invalid".utf8))
    }

    let client = makeClient(controller: controller)
    await assertClientError(expected: .decoding) {
      try await client.health()
    }
  }

  @Test func parsesNotFoundEnvelopeError() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(request: request, code: 404, body: Data("""
      {"name":"NotFoundError","data":{"message":"session missing"}}
      """.utf8))
    }

    let client = makeClient(controller: controller)
    await assertHTTPStatusError(code: 404, contains: "session missing") {
      try await client.health()
    }
  }

  @Test func parsesNotFoundEnvelopeWithoutMessage() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(request: request, code: 404, body: Data("""
      {"name":"NotFoundError","data":{}}
      """.utf8))
    }

    let client = makeClient(controller: controller)
    await assertHTTPStatusError(code: 404, contains: "Not found") {
      try await client.health()
    }
  }

  @Test func parsesBadRequestErrorArrayEnvelope() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(request: request, code: 400, body: Data("""
      {"errors":[{"path":["sessionID"],"message":"Required"}]}
      """.utf8))
    }

    let client = makeClient(controller: controller)
    await assertHTTPStatusError(code: 400, contains: "Required") {
      try await client.health()
    }
  }

  @Test func parsesBadRequestDataEnvelope() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(request: request, code: 400, body: Data("""
      {"data":{"reason":"broken","value":1}}
      """.utf8))
    }

    let client = makeClient(controller: controller)
    await assertHTTPStatusError(code: 400, contains: "{reason: broken, value: 1.0}") {
      try await client.health()
    }
  }

  @Test func parsesRawBodyError() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(request: request, code: 500, body: Data("boom".utf8))
    }

    let client = makeClient(controller: controller)
    await assertHTTPStatusError(code: 500, contains: "boom") {
      try await client.health()
    }
  }

  @Test func parsesEmptyBodyError() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(request: request, code: 500, body: Data())
    }

    let client = makeClient(controller: controller)
    await assertHTTPStatusError(code: 500, contains: nil) {
      try await client.health()
    }
  }

  @Test func requestNoContentPathWrapsTransportError() async {
    let controller = URLProtocolStubController { _ in
      throw URLError(.cannotFindHost)
    }

    let client = makeClient(controller: controller)
    await assertClientError(expected: .transport) {
      try await client.sendMessageAsync(sessionID: "ses_1", body: PromptRequest(parts: [.text("hi")]))
    }
  }

  @Test func requestNoContentPathParsesStatusError() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(request: request, code: 403, body: Data("forbidden".utf8))
    }

    let client = makeClient(controller: controller)
    await assertHTTPStatusError(code: 403, contains: "forbidden") {
      try await client.sendMessageAsync(sessionID: "ses_1", body: PromptRequest(parts: [.text("hi")]))
    }
  }

  @Test func requestNoContentPathFailsWithInvalidResponse() async {
    let controller = URLProtocolStubController { _ in
      (URLResponse(), Data())
    }

    let client = makeClient(controller: controller)
    await assertClientError(expected: .invalidResponse) {
      try await client.sendMessageAsync(sessionID: "ses_1", body: PromptRequest(parts: [.text("hi")]))
    }
  }

  @Test func errorDescriptions() {
    #expect(OpenCodeClientError.invalidURL("x").errorDescription == "Invalid server URL: x")
    #expect(OpenCodeClientError.invalidResponse.errorDescription == "Server returned an invalid response.")
    #expect(OpenCodeClientError.transport(URLError(.timedOut)).errorDescription?.contains("Network error") == true)
    #expect(OpenCodeClientError.decoding(NSError(domain: "test", code: 1)).errorDescription?.contains("Failed to decode") == true)
    #expect(OpenCodeClientError.httpStatus(code: 500, message: "boom").errorDescription == "Server error (500): boom")
    #expect(OpenCodeClientError.httpStatus(code: 500, message: nil).errorDescription == "Server error (500): No details")
    #expect(OpenCodeClientError.message("custom").errorDescription == "custom")
  }

  @Test func requestPageWrapsTransportAndInvalidResponseErrors() async {
    let transportController = URLProtocolStubController { _ in
      throw URLError(.networkConnectionLost)
    }
    let transportClient = makeClient(controller: transportController)
    await assertClientError(expected: .transport) {
      try await transportClient.listMessagesPage(sessionID: "ses_1")
    }

    let invalidController = URLProtocolStubController { _ in
      (URLResponse(), Data())
    }
    let invalidClient = makeClient(controller: invalidController)
    await assertClientError(expected: .invalidResponse) {
      try await invalidClient.listMessagesPage(sessionID: "ses_1")
    }
  }

  @Test func requestPageWrapsDecodingFailure() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(request: request, code: 200, body: Data("{not-json".utf8))
    }

    let client = makeClient(controller: controller)
    await assertClientError(expected: .decoding) {
      try await client.listMessagesPage(sessionID: "ses_1")
    }
  }
}
