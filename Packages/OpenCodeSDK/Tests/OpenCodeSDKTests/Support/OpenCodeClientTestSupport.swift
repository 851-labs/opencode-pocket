import Foundation
import OpenCodeSDK
import Testing

enum ErrorKind {
  case invalidResponse
  case transport
  case decoding
  case message
}

func makeSuccessPathController() -> URLProtocolStubController {
  URLProtocolStubController { request in
    switch (request.httpMethod, request.url?.path) {
    case ("GET", "/global/health"):
      return try makeJSONResponse(request: request, json: """
      {"healthy":true,"version":"1.2.3"}
      """)
    case ("GET", "/global/config"):
      return try makeJSONResponse(request: request, json: """
      {"model":"openai/gpt-5","share":"manual","disabled_providers":["demo"]}
      """)
    case ("PATCH", "/global/config"):
      return try makeJSONResponse(request: request, json: """
      {"model":"anthropic/claude-sonnet-4","disabled_providers":["demo","test"]}
      """)
    case ("POST", "/global/dispose"):
      return try makeJSONResponse(request: request, json: "true")
    case ("POST", "/instance/dispose"):
      return try makeJSONResponse(request: request, json: "true")
    case ("GET", "/path"):
      return try makeJSONResponse(request: request, json: """
      {"home":"/Users/opencode","state":"/Users/opencode/.config/opencode/state","config":"/Users/opencode/.config/opencode/config","worktree":"/Users/opencode/.local/opencode/worktree","directory":"/Users/opencode/projects"}
      """)
    case ("GET", "/config"):
      return try makeJSONResponse(request: request, json: """
      {"model":"anthropic/claude-sonnet-4","default_agent":"build"}
      """)
    case ("PATCH", "/config"):
      return try makeJSONResponse(request: request, json: """
      {"model":"openai/gpt-5","default_agent":"fast"}
      """)
    case ("GET", "/project/current"):
      return try makeJSONResponse(request: request, json: """
      {"id":"prj_current","worktree":"/tmp/project","vcs":"git","name":"Current","icon":{"override":"hammer"},"commands":{"start":"bun dev"},"time":{"created":1,"updated":2},"sandboxes":["main"]}
      """)
    case ("POST", "/project/git/init"):
      return try makeJSONResponse(request: request, json: """
      {"id":"prj_git","worktree":"/tmp/project","vcs":"git","name":"Git Ready","icon":null,"commands":null,"time":{"created":1,"updated":4,"initialized":4},"sandboxes":[]}
      """)
    case ("GET", "/project"):
      return try makeJSONResponse(request: request, json: """
      [{"id":"prj_1","worktree":"/tmp/project","vcs":"git","name":"Project","icon":null,"commands":null,"time":{"created":1,"updated":2},"sandboxes":[]}]
      """)
    case let ("PATCH", path) where path?.contains("/project/") == true:
      return try makeJSONResponse(request: request, json: """
      {"id":"prj_1","worktree":"/tmp/project","vcs":"git","name":"Renamed","icon":{"override":"bolt","color":"blue"},"commands":{"start":"npm start"},"time":{"created":1,"updated":3},"sandboxes":[]}
      """)
    case ("GET", "/provider/auth"):
      return try makeJSONResponse(request: request, json: """
      {"openai":[{"type":"api","label":"API key","prompts":[{"type":"text","key":"key","message":"API key"}]}]}
      """)
    case ("GET", "/provider"):
      return try makeJSONResponse(request: request, json: """
      {"all":[{"id":"openai","name":"OpenAI","source":"api","env":["OPENAI_API_KEY"],"models":{"gpt-5":{"id":"gpt-5","providerID":"openai","name":"GPT-5","status":"active","variants":{"high":{}},"limit":{"context":272000,"input":272000,"output":32000}}}}],"default":{"openai":"gpt-5"},"connected":["openai"]}
      """)
    case let ("POST", path) where path?.contains("/oauth/authorize") == true:
      return try makeJSONResponse(request: request, json: """
      {"url":"https://provider.example/auth","method":"code","instructions":"Paste the code here"}
      """)
    case let ("POST", path) where path?.contains("/oauth/callback") == true:
      return try makeJSONResponse(request: request, json: "true")
    case let ("PUT", path) where path?.contains("/auth/") == true:
      return try makeJSONResponse(request: request, json: "true")
    case let ("DELETE", path) where path?.contains("/auth/") == true:
      return try makeJSONResponse(request: request, json: "true")
    case ("GET", "/agent"):
      return try makeJSONResponse(request: request, json: """
      [{"name":"build","description":"Build agent","mode":"primary","hidden":false}]
      """)
    case ("GET", "/skill"):
      return try makeJSONResponse(request: request, json: """
      [{"name":"swift-concurrency-pro","description":"Reviews Swift concurrency code","location":"/tmp/skills/swift/SKILL.md","content":"# Skill\\nUse async await."}]
      """)
    case ("GET", "/config/providers"):
      return try makeJSONResponse(request: request, json: """
      {"providers":[{"id":"openai","name":"OpenAI","models":{"gpt-5":{"id":"gpt-5","providerID":"openai","name":"GPT-5","variants":{"high":{}}}}}],"default":{"openai":"gpt-5"}}
      """)
    case ("GET", "/lsp"):
      return try makeJSONResponse(request: request, json: """
      [{"id":"sourcekit-lsp","name":"sourcekit-lsp","root":"Packages/OpenCodeSDK","status":"connected"}]
      """)
    case ("GET", "/formatter"):
      return try makeJSONResponse(request: request, json: """
      [{"name":"swiftformat","extensions":["swift"],"enabled":true}]
      """)
    case ("GET", "/file"):
      return try makeJSONResponse(request: request, json: """
      [{"name":"src","path":"src","absolute":"/tmp/project/src","type":"directory","ignored":false},{"name":"README.md","path":"README.md","absolute":"/tmp/project/README.md","type":"file","ignored":false}]
      """)
    case ("GET", "/file/content"):
      return try makeJSONResponse(request: request, json: """
      {"type":"text","content":"print(\\\"Hello\\\")","diff":"@@ -1 +1 @@","patch":{"oldFileName":"a.swift","newFileName":"a.swift","hunks":[{"oldStart":1,"oldLines":1,"newStart":1,"newLines":1,"lines":["-old","+new"]}]},"mimeType":"text/x-swift"}
      """)
    case ("GET", "/file/status"):
      return try makeJSONResponse(request: request, json: """
      [{"path":"README.md","added":3,"removed":1,"status":"modified"}]
      """)
    case ("GET", "/find/file"):
      return try makeJSONResponse(request: request, json: """
      ["src","tests"]
      """)
    case ("GET", "/find"):
      return try makeJSONResponse(request: request, json: """
      [{"path":{"text":"Sources/App.swift"},"lines":{"text":"let value = 1"},"line_number":42,"absolute_offset":1024,"submatches":[{"match":{"text":"value"},"start":4,"end":9}]}]
      """)
    case ("GET", "/find/symbol"):
      return try makeJSONResponse(request: request, json: """
      [{"name":"renderWorkspace","kind":12,"location":{"uri":"file:///tmp/project/Sources/App.swift","range":{"start":{"line":9,"character":2},"end":{"line":14,"character":1}}}}]
      """)
    case ("GET", "/vcs"):
      return try makeJSONResponse(request: request, json: """
      {"branch":"main"}
      """)
    case ("GET", "/command"):
      return try makeJSONResponse(request: request, json: """
      [{"name":"fix","description":"Fix issues","agent":"build","model":"openai/gpt-5","source":"command","template":"Fix {{input}}","subtask":true,"hints":["be precise"]}]
      """)
    case ("GET", "/mcp"):
      return try makeJSONResponse(request: request, json: """
      {"github":{"status":"connected"},"linear":{"status":"needs_auth"}}
      """)
    case ("POST", "/mcp"):
      let body = try JSONSerialization.jsonObject(with: requestBodyData(request))
      let object = try requireDictionary(body)
      #expect(object["name"] as? String == "github")
      let config = try requireDictionary(object["config"])
      #expect(config["type"] as? String == "remote")
      #expect(config["url"] as? String == "https://mcp.example")
      return try makeJSONResponse(request: request, json: """
      {"github":{"status":"needs_auth"}}
      """)
    case let ("POST", path) where path?.hasSuffix("/auth") == true:
      return try makeJSONResponse(request: request, json: """
      {"authorizationUrl":"https://mcp.example/auth"}
      """)
    case let ("POST", path) where path?.hasSuffix("/auth/callback") == true:
      let body = try JSONSerialization.jsonObject(with: requestBodyData(request))
      let object = try requireDictionary(body)
      #expect(object["code"] as? String == "oauth-code")
      return try makeJSONResponse(request: request, json: """
      {"status":"connected"}
      """)
    case let ("POST", path) where path?.hasSuffix("/auth/authenticate") == true:
      return try makeJSONResponse(request: request, json: """
      {"status":"connected"}
      """)
    case let ("DELETE", path) where path?.hasSuffix("/auth") == true:
      return try makeJSONResponse(request: request, json: """
      {"success":true}
      """)
    case let ("POST", path) where path?.hasSuffix("/connect") == true:
      return try makeJSONResponse(request: request, json: "true")
    case let ("POST", path) where path?.hasSuffix("/disconnect") == true:
      return try makeJSONResponse(request: request, json: "true")
    case ("GET", "/session"):
      return try makeJSONResponse(request: request, json: """
      [{"id":"ses_1","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Session","version":"1","time":{"created":1,"updated":2,"archived":null},"summary":null,"share":null,"revert":null}]
      """)
    case ("GET", "/session/status"):
      return try makeJSONResponse(request: request, json: """
      {"ses_1":{"type":"busy"},"ses_2":{"type":"retry","attempt":2,"message":"Retrying","next":174000}}
      """)
    case let ("GET", path) where path?.hasSuffix("/children") == true:
      return try makeJSONResponse(request: request, json: """
      [{"id":"ses_child","slug":"child","projectID":"prj_1","directory":"/tmp/project","parentID":"ses_1","title":"Child","version":"1","time":{"created":2,"updated":3,"archived":null},"summary":null,"share":null,"revert":null}]
      """)
    case ("POST", "/session"):
      return try makeJSONResponse(request: request, json: """
      {"id":"ses_new","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Created","version":"1","time":{"created":1,"updated":1,"archived":null},"summary":null,"share":null,"revert":null}
      """)
    case let ("GET", path) where path?.contains("/message/") == true:
      return try makeJSONResponse(request: request, json: sampleMessageJSON(id: "msg_get", sessionID: "ses_1", text: "hello"))
    case let ("GET", path) where path?.hasSuffix("/message") == true:
      return try makeStatusResponse(
        request: request,
        code: 200,
        body: Data(("[" + sampleMessageJSON(id: "msg_list", sessionID: "ses_1", text: "listed") + "]").utf8),
        headers: [
          "Content-Type": "application/json",
          "Link": "<http://localhost:4096/session/ses_1/message?limit=5&before=cur_5>; rel=\"next\"",
          "X-Next-Cursor": "cur_5",
        ]
      )
    case let ("GET", path) where path?.hasSuffix("/diff") == true:
      return try makeJSONResponse(request: request, json: "[{\"file\":\"a.swift\",\"before\":\"\",\"after\":\"\",\"additions\":2,\"deletions\":1,\"status\":\"modified\"}]")
    case let ("GET", path) where path?.hasSuffix("/todo") == true:
      return try makeJSONResponse(request: request, json: """
      [{"content":"Implement API","status":"in_progress","priority":"high"}]
      """)
    case let ("GET", path) where path?.hasPrefix("/session/") == true:
      return try makeJSONResponse(request: request, json: """
      {"id":"ses_get","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Fetched","version":"1","time":{"created":1,"updated":1,"archived":null},"summary":null,"share":null,"revert":null}
      """)
    case let ("PATCH", path) where path?.contains("/part/") == true:
      let body = try JSONSerialization.jsonObject(with: requestBodyData(request))
      let object = try requireDictionary(body)
      #expect(object["id"] as? String == "part_patch_1")
      #expect(object["messageID"] as? String == "msg_1")
      return try makeJSONResponse(request: request, json: """
      {"id":"part_patch_1","sessionID":"ses_1","messageID":"msg_1","type":"text","text":"Updated text"}
      """)
    case let ("PATCH", path) where path?.hasPrefix("/session/") == true:
      return try makeJSONResponse(request: request, json: """
      {"id":"ses_patch","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Patched","version":"1","time":{"created":1,"updated":2,"archived":null},"summary":null,"share":null,"revert":null}
      """)
    case let ("DELETE", path) where path?.hasSuffix("/share") == true:
      return try makeJSONResponse(request: request, json: """
      {"id":"ses_share","slug":"share","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Unshared","version":"1","time":{"created":1,"updated":6,"archived":null},"summary":null,"share":null,"revert":null}
      """)
    case let ("DELETE", path) where path?.contains("/part/") == true:
      return try makeJSONResponse(request: request, json: "true")
    case let ("DELETE", path) where path?.hasPrefix("/session/") == true:
      return try makeJSONResponse(request: request, json: "true")
    case let ("POST", path) where path?.hasSuffix("/message") == true:
      return try makeJSONResponse(request: request, json: sampleMessageJSON(id: "msg_send", sessionID: "ses_1", text: "sent"))
    case let ("POST", path) where path?.hasSuffix("/prompt_async") == true:
      return try makeJSONResponse(request: request, json: "{}")
    case let ("POST", path) where path?.hasSuffix("/init") == true:
      let body = try JSONSerialization.jsonObject(with: requestBodyData(request))
      let object = try requireDictionary(body)
      #expect(object["providerID"] as? String == "openai")
      #expect(object["modelID"] as? String == "gpt-5")
      #expect(object["messageID"] as? String == "msg_1")
      return try makeJSONResponse(request: request, json: "true")
    case let ("POST", path) where path?.hasSuffix("/fork") == true:
      let body = try JSONSerialization.jsonObject(with: requestBodyData(request))
      let object = try requireDictionary(body)
      #expect(object["messageID"] as? String == "msg_1")
      return try makeJSONResponse(request: request, json: """
      {"id":"ses_fork","slug":"fork","projectID":"prj_1","directory":"/tmp/project","parentID":"ses_1","title":"Forked","version":"1","time":{"created":3,"updated":3,"archived":null},"summary":null,"share":null,"revert":null}
      """)
    case let ("POST", path) where path?.hasSuffix("/command") == true:
      let body = try JSONSerialization.jsonObject(with: requestBodyData(request))
      let object = try requireDictionary(body)
      #expect(object["command"] as? String == "fix")
      #expect(object["arguments"] as? String == "--all")
      #expect(object["model"] as? String == "openai/gpt-5")
      return try makeJSONResponse(request: request, json: sampleMessageJSON(id: "msg_command", sessionID: "ses_1", text: "command"))
    case let ("POST", path) where path?.hasSuffix("/shell") == true:
      let body = try JSONSerialization.jsonObject(with: requestBodyData(request))
      let object = try requireDictionary(body)
      #expect(object["command"] as? String == "git status")
      return try makeJSONResponse(request: request, json: sampleMessageJSON(id: "msg_shell", sessionID: "ses_1", text: "shell"))
    case let ("POST", path) where path?.hasSuffix("/abort") == true:
      return try makeJSONResponse(request: request, json: "true")
    case let ("POST", path) where path?.hasSuffix("/share") == true:
      return try makeJSONResponse(request: request, json: """
      {"id":"ses_share","slug":"share","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Shared","version":"1","time":{"created":1,"updated":5,"archived":null},"summary":null,"share":{"url":"https://share/opencode"},"revert":null}
      """)
    case let ("POST", path) where path?.hasSuffix("/revert") == true:
      let body = try JSONSerialization.jsonObject(with: requestBodyData(request))
      let object = try requireDictionary(body)
      #expect(object["messageID"] as? String == "msg_1")
      return try makeJSONResponse(request: request, json: """
      {"id":"ses_revert","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Reverted","version":"1","time":{"created":1,"updated":3,"archived":null},"summary":null,"share":null,"revert":{"messageID":"msg_1"}}
      """)
    case let ("POST", path) where path?.hasSuffix("/unrevert") == true:
      return try makeJSONResponse(request: request, json: """
      {"id":"ses_revert","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Restored","version":"1","time":{"created":1,"updated":4,"archived":null},"summary":null,"share":null,"revert":null}
      """)
    case let ("POST", path) where path?.hasSuffix("/summarize") == true:
      let body = try JSONSerialization.jsonObject(with: requestBodyData(request))
      let object = try requireDictionary(body)
      #expect(object["providerID"] as? String == "openai")
      #expect(object["modelID"] as? String == "gpt-5")
      return try makeJSONResponse(request: request, json: "true")
    case ("GET", "/permission"):
      return try makeJSONResponse(request: request, json: """
      [{"id":"perm_1","sessionID":"ses_1","permission":"edit","patterns":["src/**"],"metadata":{"tool":"edit"},"always":[],"tool":{"messageID":"msg_1","callID":"call_1"}}]
      """)
    case let ("POST", path) where path?.contains("/permission/") == true:
      return try makeJSONResponse(request: request, json: "true")
    case ("GET", "/question"):
      return try makeJSONResponse(request: request, json: """
      [{"id":"question_1","sessionID":"ses_1","questions":[{"question":"Pick one","header":"Choice","options":[{"label":"Yes","description":"Confirm"}],"multiple":false,"custom":true}],"tool":{"messageID":"msg_2","callID":"call_2"}}]
      """)
    case let ("POST", path) where path?.contains("/question/") == true:
      return try makeJSONResponse(request: request, json: "true")
    default:
      throw OpenCodeClientError.message("Unexpected request: \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "nil")")
    }
  }
}

func makeClient(controller: URLProtocolStubController, directory: String? = "/tmp/default") -> OpenCodeClient {
  let config = URLSessionConfiguration.ephemeral
  config.protocolClasses = [URLProtocolStub.self]
  config.httpAdditionalHeaders = [URLProtocolStub.controllerIDHeader: controller.id]
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

func assertClientError<T>(
  expected: ErrorKind,
  operation: () async throws -> T,
  sourceLocation: SourceLocation = #_sourceLocation
) async {
  do {
    _ = try await operation()
    #expect(Bool(false), "Expected an OpenCodeClientError.", sourceLocation: sourceLocation)
  } catch let error as OpenCodeClientError {
    let matched = switch (expected, error) {
    case (.invalidResponse, .invalidResponse),
         (.transport, .transport),
         (.decoding, .decoding),
         (.message, .message):
      true
    default:
      false
    }

    #expect(matched, "Unexpected error: \(error)", sourceLocation: sourceLocation)
  } catch {
    #expect(Bool(false), "Unexpected non-client error: \(error)", sourceLocation: sourceLocation)
  }
}

func assertHTTPStatusError<T>(
  code: Int,
  contains fragment: String?,
  operation: () async throws -> T,
  sourceLocation: SourceLocation = #_sourceLocation
) async {
  do {
    _ = try await operation()
    #expect(Bool(false), "Expected an HTTP status error.", sourceLocation: sourceLocation)
  } catch let error as OpenCodeClientError {
    guard case let .httpStatus(statusCode, message) = error else {
      #expect(Bool(false), "Unexpected error: \(error)", sourceLocation: sourceLocation)
      return
    }

    #expect(statusCode == code, sourceLocation: sourceLocation)
    if let fragment {
      #expect(message?.contains(fragment) == true, sourceLocation: sourceLocation)
    } else {
      #expect(message == nil, sourceLocation: sourceLocation)
    }
  } catch {
    #expect(Bool(false), "Unexpected non-client error: \(error)", sourceLocation: sourceLocation)
  }
}

final class URLProtocolStubController: @unchecked Sendable {
  let id = UUID().uuidString

  private let lock = NSLock()
  private let handler: @Sendable (URLRequest) async throws -> (URLResponse, Data)
  private let firstRequestSignal = AsyncSignal()
  private let stopLoadingSignal = AsyncSignal()
  private var requests: [URLRequest] = []

  init(handler: @escaping @Sendable (URLRequest) async throws -> (URLResponse, Data)) {
    self.handler = handler
    URLProtocolStub.register(self)
  }

  deinit {
    URLProtocolStub.unregister(id)
  }

  var recordedRequests: [URLRequest] {
    lock.withLock {
      requests
    }
  }

  func respond(to request: URLRequest) async throws -> (URLResponse, Data) {
    lock.withLock {
      requests.append(request)
    }
    firstRequestSignal.fire()
    return try await handler(request)
  }

  func notifyStopLoading() {
    stopLoadingSignal.fire()
  }

  func waitForFirstRequest() async {
    await firstRequestSignal.wait()
  }

  func waitForStopLoading() async {
    await stopLoadingSignal.wait()
  }
}

final class AsyncSignal: @unchecked Sendable {
  private let lock = NSLock()
  private var hasFired = false
  private var continuations: [CheckedContinuation<Void, Never>] = []

  func fire() {
    let pending: [CheckedContinuation<Void, Never>] = lock.withLock {
      guard !hasFired else {
        return []
      }

      hasFired = true
      let continuations = continuations
      self.continuations.removeAll()
      return continuations
    }

    pending.forEach { $0.resume() }
  }

  func wait() async {
    let shouldReturnImmediately = lock.withLock {
      hasFired
    }
    if shouldReturnImmediately {
      return
    }

    await withCheckedContinuation { continuation in
      let continuationToResume: CheckedContinuation<Void, Never>? = lock.withLock {
        if hasFired {
          return continuation
        }

        continuations.append(continuation)
        return nil
      }

      continuationToResume?.resume()
    }
  }
}

final class URLProtocolStub: URLProtocol, @unchecked Sendable {
  static let controllerIDHeader = "X-OpenCode-Test-ID"

  private static let controllerRegistry = URLProtocolControllerRegistry()

  private var controller: URLProtocolStubController?
  private var loadProxy: URLProtocolLoadProxy?
  private var loadingTask: Task<Void, Never>?

  static func register(_ controller: URLProtocolStubController) {
    controllerRegistry.register(controller)
  }

  static func unregister(_ id: String) {
    controllerRegistry.unregister(id)
  }

  private static func controller(for id: String) -> URLProtocolStubController? {
    controllerRegistry.controller(for: id)
  }

  override class func canInit(with _: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let controllerID = request.value(forHTTPHeaderField: Self.controllerIDHeader),
          let controller = Self.controller(for: controllerID)
    else {
      client?.urlProtocol(self, didFailWithError: URLError(.badURL))
      return
    }

    self.controller = controller
    let request = request
    let loadProxy = URLProtocolLoadProxy(stub: self, client: client)
    self.loadProxy = loadProxy

    loadingTask = Task { [controller, request, loadProxy] in
      do {
        let (response, data) = try await controller.respond(to: request)
        guard !Task.isCancelled else {
          return
        }
        loadProxy.finish(response: response, data: data)
      } catch {
        guard !Task.isCancelled else {
          return
        }
        loadProxy.fail(error)
      }
    }
  }

  override func stopLoading() {
    loadProxy?.stop()
    loadProxy = nil
    controller?.notifyStopLoading()
    loadingTask?.cancel()
    loadingTask = nil
  }
}

private final class URLProtocolControllerRegistry: @unchecked Sendable {
  private let lock = NSLock()
  private var controllers: [String: URLProtocolStubController] = [:]

  func register(_ controller: URLProtocolStubController) {
    lock.withLock {
      controllers[controller.id] = controller
    }
  }

  func unregister(_ id: String) {
    lock.withLock {
      controllers[id] = nil
    }
  }

  func controller(for id: String) -> URLProtocolStubController? {
    lock.withLock {
      controllers[id]
    }
  }
}

private final class URLProtocolLoadProxy: @unchecked Sendable {
  private let lock = NSLock()
  private weak var stub: URLProtocolStub?
  private let client: (any URLProtocolClient)?
  private var isStopped = false

  init(stub: URLProtocolStub, client: (any URLProtocolClient)?) {
    self.stub = stub
    self.client = client
  }

  func stop() {
    lock.withLock {
      isStopped = true
    }
  }

  func finish(response: URLResponse, data: Data) {
    guard let stub = activeStub() else {
      return
    }

    client?.urlProtocol(stub, didReceive: response, cacheStoragePolicy: .notAllowed)
    if !data.isEmpty {
      client?.urlProtocol(stub, didLoad: data)
    }
    client?.urlProtocolDidFinishLoading(stub)
  }

  func fail(_ error: any Error) {
    guard let stub = activeStub() else {
      return
    }

    client?.urlProtocol(stub, didFailWithError: error)
  }

  private func activeStub() -> URLProtocolStub? {
    lock.withLock {
      guard !isStopped else {
        return nil
      }

      return stub
    }
  }
}

func suspendUntilCancelled(signal: AsyncSignal) async throws {
  try await withTaskCancellationHandler {
    while true {
      try await Task.sleep(nanoseconds: 60_000_000_000)
    }
  } onCancel: {
    signal.fire()
  }
}

func requireDictionary(_ value: Any?) throws -> [String: Any] {
  guard let dictionary = value as? [String: Any] else {
    throw OpenCodeClientError.message("Expected dictionary payload")
  }
  return dictionary
}

func requireURL(from request: URLRequest) throws -> URL {
  guard let url = request.url else {
    throw OpenCodeClientError.message("Request URL is missing")
  }
  return url
}

func requestBodyData(_ request: URLRequest) throws -> Data {
  if let body = request.httpBody {
    return body
  }

  guard let stream = request.httpBodyStream else {
    throw OpenCodeClientError.message("Request body is missing")
  }

  stream.open()
  defer {
    stream.close()
  }

  var data = Data()
  var buffer = [UInt8](repeating: 0, count: 1024)

  while stream.hasBytesAvailable {
    let bytesRead = stream.read(&buffer, maxLength: buffer.count)
    if bytesRead < 0 {
      throw stream.streamError ?? OpenCodeClientError.invalidResponse
    }
    if bytesRead == 0 {
      break
    }
    data.append(buffer, count: bytesRead)
  }

  return data
}

func makeStatusResponse(
  request: URLRequest,
  code: Int,
  body: Data,
  headers: [String: String] = ["Content-Type": "application/json"]
) throws -> (URLResponse, Data) {
  let url = try requireURL(from: request)
  guard let response = HTTPURLResponse(url: url, statusCode: code, httpVersion: "HTTP/1.1", headerFields: headers) else {
    throw OpenCodeClientError.message("Failed to build HTTP response")
  }
  return (response, body)
}

func makeJSONResponse(request: URLRequest, json: String) throws -> (URLResponse, Data) {
  try makeStatusResponse(request: request, code: 200, body: Data(json.utf8))
}

func sampleMessageJSON(id: String, sessionID: String, text: String) -> String {
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

extension NSLock {
  func withLock<T>(_ body: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try body()
  }
}
