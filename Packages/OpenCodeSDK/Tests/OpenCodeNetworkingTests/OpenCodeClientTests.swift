import Foundation
import OpenCodeModels
import OpenCodeNetworking
import Testing

@Suite(.tags(.networking))
struct OpenCodeClientTests {
  @Test func endpointsAndSuccessPaths() async throws {
    let controller = URLProtocolStubController { request in
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
      case ("GET", "/vcs"):
        return try makeJSONResponse(request: request, json: """
        {"branch":"main"}
        """)
      case ("GET", "/session"):
        return try makeJSONResponse(request: request, json: """
        [{"id":"ses_1","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Session","version":"1","time":{"created":1,"updated":2,"archived":null},"summary":null,"share":null,"revert":null}]
        """)
      case ("GET", "/session/status"):
        return try makeJSONResponse(request: request, json: """
        {"ses_1":{"type":"busy"},"ses_2":{"type":"retry","attempt":2,"message":"Retrying","next":174000}}
        """)
      case ("GET", "/agent"):
        return try makeJSONResponse(request: request, json: """
        [{"name":"build","description":"Build agent","mode":"primary","hidden":false}]
        """)
      case ("GET", "/config/providers"):
        return try makeJSONResponse(request: request, json: """
        {"providers":[{"id":"openai","name":"OpenAI","models":{"gpt-5":{"id":"gpt-5","providerID":"openai","name":"GPT-5","variants":{"high":{}}}}}],"default":{"openai":"gpt-5"}}
        """)
      case ("GET", "/lsp"):
        return try makeJSONResponse(request: request, json: """
        [{"id":"sourcekit-lsp","name":"sourcekit-lsp","root":"Packages/OpenCodeSDK","status":"connected"}]
        """)
      case ("GET", "/mcp"):
        return try makeJSONResponse(request: request, json: """
        {"github":{"status":"connected"},"linear":{"status":"needs_auth"}}
        """)
      case ("POST", "/session"):
        return try makeJSONResponse(request: request, json: """
        {"id":"ses_new","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Created","version":"1","time":{"created":1,"updated":1,"archived":null},"summary":null,"share":null,"revert":null}
        """)
      case let ("GET", path) where path?.contains("/message/") == true:
        return try makeJSONResponse(request: request, json: Self.messageJSON(id: "msg_get", sessionID: "ses_1", text: "hello"))
      case let ("GET", path) where path?.hasSuffix("/message") == true:
        return try makeStatusResponse(
          request: request,
          code: 200,
          body: Data("[\(Self.messageJSON(id: "msg_list", sessionID: "ses_1", text: "listed"))]".utf8),
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
      case let ("PATCH", path) where path?.hasPrefix("/session/") == true:
        return try makeJSONResponse(request: request, json: """
        {"id":"ses_patch","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Patched","version":"1","time":{"created":1,"updated":2,"archived":null},"summary":null,"share":null,"revert":null}
        """)
      case let ("DELETE", path) where path?.hasPrefix("/session/") == true:
        return try makeJSONResponse(request: request, json: "true")
      case let ("POST", path) where path?.hasSuffix("/message") == true:
        return try makeJSONResponse(request: request, json: Self.messageJSON(id: "msg_send", sessionID: "ses_1", text: "sent"))
      case let ("POST", path) where path?.hasSuffix("/prompt_async") == true:
        return try makeJSONResponse(request: request, json: "{}")
      case let ("POST", path) where path?.hasSuffix("/abort") == true:
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

    let client = makeClient(controller: controller, directory: "/tmp/default")

    let health = try await client.health()
    #expect(health.healthy == true)
    #expect(health.version == "1.2.3")

    let globalConfig = try await client.getGlobalConfig()
    #expect(globalConfig["model"]?.stringValue == "openai/gpt-5")

    let updatedGlobalConfig = try await client.updateGlobalConfig([
      "model": .string("anthropic/claude-sonnet-4"),
      "disabled_providers": .array([.string("demo"), .string("test")]),
    ])
    #expect(updatedGlobalConfig["disabled_providers"]?.arrayValue?.count == 2)

    let disposedGlobal = try await client.disposeGlobal()
    #expect(disposedGlobal == true)

    let pathInfo = try await client.getPath()
    #expect(pathInfo.home == "/Users/opencode")

    let config = try await client.getConfig()
    #expect(config["default_agent"]?.stringValue == "build")

    let updatedConfig = try await client.updateConfig([
      "model": .string("openai/gpt-5"),
      "default_agent": .string("fast"),
    ])
    #expect(updatedConfig["default_agent"]?.stringValue == "fast")

    let projects = try await client.listProjects()
    #expect(projects.first?.id == "prj_1")

    let currentProject = try await client.getCurrentProject()
    #expect(currentProject.id == "prj_current")
    #expect(currentProject.commands?.start == "bun dev")

    let updatedProject = try await client.updateProject(
      id: "prj_1",
      body: ProjectUpdateRequest(name: "Renamed", icon: ProjectIcon(url: nil, override: "bolt", color: "blue"), commands: ProjectCommands(start: "npm start"))
    )
    #expect(updatedProject.name == "Renamed")
    #expect(updatedProject.icon?.override == "bolt")

    let providerList = try await client.listProviders()
    #expect(providerList.all.first?.id == "openai")
    #expect(providerList.connected == ["openai"])

    let authMethods = try await client.listProviderAuthMethods()
    #expect(authMethods["openai"]?.first?.type == "api")

    let oauth = try await client.authorizeProviderOAuth(providerID: "openai", method: 0, inputs: ["region": "us"])
    #expect(oauth?.url == "https://provider.example/auth")

    let oauthCallback = try await client.callbackProviderOAuth(providerID: "openai", method: 0, code: "abc123")
    #expect(oauthCallback == true)

    let authSet = try await client.setAuth(providerID: "openai", auth: .api(key: "secret"))
    #expect(authSet == true)

    let authRemoved = try await client.removeAuth(providerID: "openai")
    #expect(authRemoved == true)

    let agents = try await client.listAgents()
    #expect(agents.first?.name == "build")

    let listedFiles = try await client.listFiles(path: "", directory: "/tmp/project")
    #expect(listedFiles.count == 2)
    #expect(listedFiles.first?.type == .directory)

    let fileContent = try await client.readFile(path: "README.md", directory: "/tmp/project")
    #expect(fileContent.type == .text)
    #expect(fileContent.mimeType == "text/x-swift")

    let fileStatus = try await client.listFileStatus()
    #expect(fileStatus.first?.path == "README.md")
    #expect(fileStatus.first?.status == .modified)

    let vcs = try await client.getVCSInfo()
    #expect(vcs.branch == "main")

    let directoryMatches = try await client.findFiles(
      query: "src",
      includeDirectories: true,
      type: .directory,
      limit: 10,
      directory: "/tmp/project"
    )
    #expect(directoryMatches == ["src", "tests"])

    let sessions = try await client.listSessions(roots: true, limit: 10)
    #expect(sessions.count == 1)

    let sessionStatuses = try await client.listSessionStatuses()
    #expect(sessionStatuses["ses_1"]?.type == .busy)
    #expect(sessionStatuses["ses_2"]?.type == .retry)

    let configProviders = try await client.listConfigProviders()
    #expect(configProviders.providers.first?.id == "openai")

    let lspStatus = try await client.listLSPStatus()
    #expect(lspStatus.first?.id == "sourcekit-lsp")
    #expect(lspStatus.first?.status == .connected)

    let mcpStatus = try await client.listMCPStatus()
    #expect(mcpStatus["github"]?.status == .connected)
    #expect(mcpStatus["linear"]?.status == .needsAuth)

    let created = try await client.createSession(SessionCreateRequest(title: "Hi"))
    #expect(created.id == "ses_new")

    let fetched = try await client.getSession(id: "ses 1")
    #expect(fetched.id == "ses_get")

    let updated = try await client.updateSession(id: "ses 1", body: SessionUpdateRequest(title: "Renamed"))
    #expect(updated.id == "ses_patch")

    let deleted = try await client.deleteSession(id: "ses_1")
    #expect(deleted == true)

    let listedMessages = try await client.listMessages(sessionID: "ses_1", limit: 5, before: "cur_0")
    #expect(listedMessages.first?.id == "msg_list")

    let listedMessagesPage = try await client.listMessagesPage(sessionID: "ses_1", limit: 5)
    #expect(listedMessagesPage.nextCursor == "cur_5")
    #expect(listedMessagesPage.nextURL?.absoluteString == "http://localhost:4096/session/ses_1/message?limit=5&before=cur_5")

    let fetchedMessage = try await client.getMessage(sessionID: "ses_1", messageID: "msg_1")
    #expect(fetchedMessage.id == "msg_get")

    let diffs = try await client.getSessionDiff(sessionID: "ses_1", messageID: "msg_1")
    #expect(diffs.first?.file == "a.swift")

    let todos = try await client.getSessionTodo(sessionID: "ses_1")
    #expect(todos.first?.content == "Implement API")

    let sent = try await client.sendMessage(sessionID: "ses_1", body: PromptRequest(parts: [.text("Hello")]))
    #expect(sent.id == "msg_send")

    try await client.sendMessageAsync(sessionID: "ses_1", body: PromptRequest(parts: [.text("async")]))

    let aborted = try await client.abortSession(sessionID: "ses_1")
    #expect(aborted == true)

    let permissions = try await client.listPermissions()
    #expect(permissions.first?.id == "perm_1")

    let repliedPermission = try await client.respondPermission(requestID: "perm_1", response: .once, message: "Proceed")
    #expect(repliedPermission == true)

    let questions = try await client.listQuestions()
    #expect(questions.first?.id == "question_1")

    let repliedQuestion = try await client.replyQuestion(requestID: "question_1", answers: [["Yes"]])
    #expect(repliedQuestion == true)

    let rejectedQuestion = try await client.rejectQuestion(requestID: "question_1")
    #expect(rejectedQuestion == true)

    let requests = controller.recordedRequests
    #expect(requests.contains { $0.url?.path == "/global/config" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/global/config" && $0.httpMethod == "PATCH" })
    #expect(requests.contains { $0.url?.path == "/global/dispose" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/config" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/config" && $0.httpMethod == "PATCH" })
    #expect(requests.contains { $0.url?.path == "/project" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/project/current" && $0.url?.query?.contains("directory=/tmp/default") == true })
    #expect(requests.contains { $0.url?.path == "/project/prj_1" && $0.httpMethod == "PATCH" })
    #expect(requests.contains { $0.url?.path == "/provider" && $0.url?.query?.contains("directory=/tmp/default") == true })
    #expect(requests.contains { $0.url?.path == "/provider/auth" && $0.url?.query?.contains("directory=/tmp/default") == true })
    #expect(requests.contains { $0.url?.path == "/provider/openai/oauth/authorize" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/provider/openai/oauth/callback" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/auth/openai" && $0.httpMethod == "PUT" })
    #expect(requests.contains { $0.url?.path == "/auth/openai" && $0.httpMethod == "DELETE" })
    #expect(requests.contains { $0.url?.path == "/session" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/session" && $0.url?.query?.contains("directory=/tmp/default") == true })
    #expect(requests.contains { $0.url?.path == "/session" && $0.url?.query?.contains("roots=true") == true })
    #expect(requests.contains { $0.url?.path == "/session" && $0.url?.query?.contains("limit=10") == true })
    #expect(requests.contains { $0.url?.path == "/session/status" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/path" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/file" && $0.url?.query?.contains("path=") == true })
    #expect(requests.contains { $0.url?.path == "/file/content" && $0.url?.query?.contains("path=README.md") == true })
    #expect(requests.contains { $0.url?.path == "/file/status" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/find/file" && $0.url?.query?.contains("type=directory") == true })
    #expect(requests.contains { $0.url?.path == "/find/file" && $0.url?.query?.contains("dirs=true") == true })
    #expect(requests.contains { $0.url?.path == "/find/file" && $0.url?.query?.contains("limit=10") == true })
    #expect(requests.contains { $0.url?.path == "/vcs" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/lsp" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/mcp" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path.contains("/session/ses") == true && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.absoluteString.contains("limit=5") == true })
    #expect(requests.contains { $0.url?.absoluteString.contains("before=cur_0") == true })
    #expect(requests.contains { $0.url?.absoluteString.contains("messageID=msg_1") == true })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/todo" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/permission" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/permission/perm_1/reply" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/question" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/question/question_1/reply" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/question/question_1/reject" && $0.httpMethod == "POST" })
  }

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
    let archiveTime = 1_761_224_322_123.0

    let controller = URLProtocolStubController { request in
      #expect(request.httpMethod == "PATCH")
      #expect(request.url?.path == "/session/ses_1")

      let bodyData = try requestBodyData(request)
      let bodyObject = try JSONSerialization.jsonObject(with: bodyData)
      let body = try requireDictionary(bodyObject)
      let time = try requireDictionary(body["time"])

      #expect(time["archived"] as? Double == archiveTime)

      return try makeJSONResponse(request: request, json: """
      {"id":"ses_patch","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Patched","version":"1","time":{"created":1,"updated":2,"archived":null},"summary":null,"share":null,"revert":null}
      """)
    }

    let client = makeClient(controller: controller, directory: "/tmp/project")
    _ = try await client.updateSession(
      id: "ses_1",
      body: SessionUpdateRequest(time: SessionUpdateTime(archived: archiveTime))
    )
  }

  @Test func updateSessionSendsArchivedNullPayloadForUnarchive() async throws {
    let controller = URLProtocolStubController { request in
      #expect(request.httpMethod == "PATCH")
      #expect(request.url?.path == "/session/ses_1")

      let bodyData = try requestBodyData(request)
      let bodyObject = try JSONSerialization.jsonObject(with: bodyData)
      let body = try requireDictionary(bodyObject)
      let time = try requireDictionary(body["time"])

      #expect(time["archived"] is NSNull)

      return try makeJSONResponse(request: request, json: """
      {"id":"ses_patch","slug":"slug","projectID":"prj_1","directory":"/tmp/project","parentID":null,"title":"Patched","version":"1","time":{"created":1,"updated":2,"archived":null},"summary":null,"share":null,"revert":null}
      """)
    }

    let client = makeClient(controller: controller, directory: "/tmp/project")
    _ = try await client.updateSession(
      id: "ses_1",
      body: SessionUpdateRequest(time: SessionUpdateTime.clearArchived())
    )
  }

  @Test func requestFailsWithInvalidResponse() async {
    let controller = URLProtocolStubController { request in
      let url = try requireURL(from: request)
      let response = URLResponse(url: url, mimeType: "application/json", expectedContentLength: 2, textEncodingName: nil)
      return (response, Data("{}".utf8))
    }

    let client = makeClient(controller: controller)
    await assertClientError(expected: .invalidResponse) {
      try await client.health()
    }
  }

  @Test func requestWrapsTransportError() async {
    let controller = URLProtocolStubController { _ in
      throw URLError(.timedOut)
    }

    let client = makeClient(controller: controller)
    await assertClientError(expected: .transport) {
      try await client.health()
    }
  }

  @Test func requestThrowsDecodingError() async {
    let controller = URLProtocolStubController { request in
      try makeJSONResponse(request: request, json: "{\"healthy\":\"oops\"}")
    }

    let client = makeClient(controller: controller)
    await assertClientError(expected: .decoding) {
      try await client.health()
    }
  }

  @Test func parsesNotFoundEnvelopeError() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(
        request: request,
        code: 404,
        body: Data("{\"name\":\"NotFoundError\",\"data\":{\"message\":\"Missing\"}}".utf8)
      )
    }

    let client = makeClient(controller: controller)
    await assertHTTPStatusError(code: 404, contains: "Missing") {
      try await client.health()
    }
  }

  @Test func parsesNotFoundEnvelopeWithoutMessage() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(
        request: request,
        code: 404,
        body: Data("{\"name\":\"NotFoundError\",\"data\":{}}".utf8)
      )
    }

    let client = makeClient(controller: controller)
    await assertHTTPStatusError(code: 404, contains: "Not found") {
      try await client.health()
    }
  }

  @Test func parsesBadRequestErrorArrayEnvelope() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(
        request: request,
        code: 400,
        body: Data("{\"errors\":[{\"message\":\"Bad input\"}],\"success\":false}".utf8)
      )
    }

    let client = makeClient(controller: controller)
    await assertHTTPStatusError(code: 400, contains: "Bad input") {
      try await client.health()
    }
  }

  @Test func parsesBadRequestDataEnvelope() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(
        request: request,
        code: 400,
        body: Data("{\"data\":{\"message\":\"Data error\"},\"success\":false}".utf8)
      )
    }

    let client = makeClient(controller: controller)
    await assertHTTPStatusError(code: 400, contains: "Data error") {
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
      throw URLError(.cannotConnectToHost)
    }

    let client = makeClient(controller: controller)
    await assertClientError(expected: .transport) {
      try await client.sendMessageAsync(sessionID: "ses_1", body: PromptRequest(parts: [.text("x")]))
    }
  }

  @Test func requestNoContentPathParsesStatusError() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(
        request: request,
        code: 400,
        body: Data("{\"errors\":[{\"message\":\"No content failed\"}],\"success\":false}".utf8)
      )
    }

    let client = makeClient(controller: controller)
    await assertHTTPStatusError(code: 400, contains: "No content failed") {
      try await client.sendMessageAsync(sessionID: "ses_1", body: PromptRequest(parts: [.text("x")]))
    }
  }

  @Test func requestNoContentPathFailsWithInvalidResponse() async {
    let controller = URLProtocolStubController { request in
      let url = try requireURL(from: request)
      let response = URLResponse(url: url, mimeType: "application/json", expectedContentLength: 0, textEncodingName: nil)
      return (response, Data())
    }

    let client = makeClient(controller: controller)
    await assertClientError(expected: .invalidResponse) {
      try await client.sendMessageAsync(sessionID: "ses_1", body: PromptRequest(parts: [.text("x")]))
    }
  }

  @Test func encodeBodyFailureReturnsMessageError() async {
    let controller = URLProtocolStubController { request in
      try makeJSONResponse(request: request, json: "{}")
    }

    let client = makeClient(controller: controller)
    await assertClientError(expected: .message) {
      try await client.updateSession(
        id: "ses_1",
        body: SessionUpdateRequest(time: SessionUpdateTime(archived: .nan))
      )
    }
  }

  @Test func subscribeEventsParsesStreamReconnectsAndSendsLastEventID() async {
    let lock = NSLock()
    var attempts = 0
    let controller = URLProtocolStubController { request in
      let currentAttempt: Int = lock.withLock {
        attempts += 1
        return attempts
      }

      switch currentAttempt {
      case 1:
        #expect(request.value(forHTTPHeaderField: "Accept") == "text/event-stream")
        #expect(request.value(forHTTPHeaderField: "Last-Event-ID") == nil)
        return try makeStatusResponse(
          request: request,
          code: 200,
          body: Data("id: evt-1\nretry: 1\ndata: {\"type\":\"server.connected\",\"properties\":{}}\n\ndata: not-json\n\n".utf8)
        )
      case 2:
        #expect(request.value(forHTTPHeaderField: "Last-Event-ID") == "evt-1")
        let url = try requireURL(from: request)
        let response = URLResponse(
          url: url,
          mimeType: "text/event-stream",
          expectedContentLength: 0,
          textEncodingName: nil
        )
        return (response, Data())
      case 3:
        #expect(request.value(forHTTPHeaderField: "Last-Event-ID") == "evt-1")
        return try makeStatusResponse(request: request, code: 503, body: Data())
      default:
        #expect(request.value(forHTTPHeaderField: "Last-Event-ID") == "evt-1")
        return try makeStatusResponse(
          request: request,
          code: 200,
          body: Data("data: {\"type\":\"server.heartbeat\",\"properties\":{}}\n\n".utf8)
        )
      }
    }

    let client = makeClient(controller: controller)
    let stream = client.subscribeEvents()

    var received: [ServerEvent] = []
    var iterator = stream.makeAsyncIterator()
    while let event = await iterator.next() {
      received.append(event)
      if received.count == 3 {
        break
      }
    }

    #expect(received.map(\.type) == ["server.connected", "event.decode.error", "server.heartbeat"])
    #expect(controller.recordedRequests.count >= 4)
  }

  @Test func subscribeGlobalEventsParsesDirectoryAndFallsBackToGlobal() async {
    let controller = URLProtocolStubController { request in
      #expect(request.url?.path == "/global/event")
      return try makeStatusResponse(
        request: request,
        code: 200,
        body: Data("data: {\"payload\":{\"type\":\"server.connected\",\"properties\":{}}}\n\ndata: {\"directory\":\"/tmp/project\",\"payload\":{\"type\":\"project.updated\",\"properties\":{\"id\":\"prj_1\"}}}\n\n".utf8)
      )
    }

    let client = makeClient(controller: controller)
    var iterator = client.subscribeGlobalEvents().makeAsyncIterator()
    let first = await iterator.next()
    let second = await iterator.next()

    #expect(first?.resolvedDirectory == "global")
    #expect(first?.payload.type == "server.connected")
    #expect(second?.resolvedDirectory == "/tmp/project")
    #expect(second?.payload.type == "project.updated")
  }

  @Test func subscribeEventsIgnoresEmptyPayloadDataFrame() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(
        request: request,
        code: 200,
        body: Data("data:   \n\ndata: {\"type\":\"server.connected\",\"properties\":{}}\n\n".utf8)
      )
    }

    let client = makeClient(controller: controller)
    var iterator = client.subscribeEvents().makeAsyncIterator()
    let first = await iterator.next()

    #expect(first?.type == "server.connected")
  }

  @Test func subscribeEventsFlushesRemainingBufferWithoutDelimiter() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(
        request: request,
        code: 200,
        body: Data("data: {\"type\":\"server.connected\",\"properties\":{}}".utf8)
      )
    }

    let client = makeClient(controller: controller)
    var iterator = client.subscribeEvents().makeAsyncIterator()
    let first = await iterator.next()

    #expect(first?.type == "server.connected")
  }

  @Test(.timeLimit(.minutes(1)))
  func subscribeEventsStopsWhenConsumerCancels() async {
    let handlerCancelled = AsyncSignal()
    let controller = URLProtocolStubController { _ in
      try await suspendUntilCancelled(signal: handlerCancelled)
      throw URLError(.cancelled)
    }

    let client = makeClient(controller: controller)
    let stream = client.subscribeEvents()

    let consumer = Task {
      var iterator = stream.makeAsyncIterator()
      _ = await iterator.next()
    }

    await controller.waitForFirstRequest()
    consumer.cancel()
    await controller.waitForStopLoading()
    await handlerCancelled.wait()
    _ = await consumer.result

    #expect(controller.recordedRequests.count >= 1)
  }

  @Test func subscribeEventsCancelsDuringBufferedByteIteration() async {
    let trailingPayload = String(repeating: "x", count: 750_000)
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(
        request: request,
        code: 200,
        body: Data("data: {\"type\":\"server.connected\",\"properties\":{}}\n\n\(trailingPayload)".utf8)
      )
    }

    let client = makeClient(controller: controller)
    var iterator = client.subscribeEvents().makeAsyncIterator()
    let first = await iterator.next()

    #expect(first?.type == "server.connected")
  }

  @Test(.timeLimit(.minutes(1)))
  func subscribeEventsCancellationWhileConnecting() async {
    let handlerCancelled = AsyncSignal()
    let controller = URLProtocolStubController { _ in
      try await suspendUntilCancelled(signal: handlerCancelled)
      throw URLError(.cancelled)
    }

    let client = makeClient(controller: controller, directory: nil)
    let stream = client.subscribeEvents()

    let consumer = Task {
      var iterator = stream.makeAsyncIterator()
      _ = await iterator.next()
    }

    await controller.waitForFirstRequest()
    consumer.cancel()
    await controller.waitForStopLoading()
    await handlerCancelled.wait()
    _ = await consumer.result

    #expect(controller.recordedRequests.count == 1)
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

  private func makeClient(controller: URLProtocolStubController, directory: String? = "/tmp/default") -> OpenCodeClient {
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

  private func assertClientError<T>(
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

  private func assertHTTPStatusError<T>(
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
}

private enum ErrorKind {
  case invalidResponse
  case transport
  case decoding
  case message
}

private final class URLProtocolStubController: @unchecked Sendable {
  let id = UUID().uuidString

  private let lock = NSLock()
  private let handler: (URLRequest) async throws -> (URLResponse, Data)
  private let firstRequestSignal = AsyncSignal()
  private let stopLoadingSignal = AsyncSignal()
  private var requests: [URLRequest] = []

  init(handler: @escaping (URLRequest) async throws -> (URLResponse, Data)) {
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

private final class AsyncSignal: @unchecked Sendable {
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

private final class URLProtocolStub: URLProtocol {
  static let controllerIDHeader = "X-OpenCode-Test-ID"

  private static let lock = NSLock()
  private static var controllers: [String: URLProtocolStubController] = [:]

  private var controller: URLProtocolStubController?
  private var loadingTask: Task<Void, Never>?

  static func register(_ controller: URLProtocolStubController) {
    lock.withLock {
      controllers[controller.id] = controller
    }
  }

  static func unregister(_ id: String) {
    lock.withLock {
      controllers[id] = nil
    }
  }

  private static func controller(for id: String) -> URLProtocolStubController? {
    lock.withLock {
      controllers[id]
    }
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
    let urlProtocolClient = client
    let request = request

    loadingTask = Task {
      do {
        let (response, data) = try await controller.respond(to: request)
        guard !Task.isCancelled else {
          return
        }
        urlProtocolClient?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if !data.isEmpty {
          urlProtocolClient?.urlProtocol(self, didLoad: data)
        }
        urlProtocolClient?.urlProtocolDidFinishLoading(self)
      } catch {
        guard !Task.isCancelled else {
          return
        }
        urlProtocolClient?.urlProtocol(self, didFailWithError: error)
      }
    }
  }

  override func stopLoading() {
    controller?.notifyStopLoading()
    loadingTask?.cancel()
    loadingTask = nil
  }
}

private func suspendUntilCancelled(signal: AsyncSignal) async throws {
  try await withTaskCancellationHandler {
    while true {
      try await Task.sleep(nanoseconds: 60_000_000_000)
    }
  } onCancel: {
    signal.fire()
  }
}

private func requireDictionary(_ value: Any?) throws -> [String: Any] {
  guard let dictionary = value as? [String: Any] else {
    throw OpenCodeClientError.message("Expected dictionary payload")
  }
  return dictionary
}

private func requireURL(from request: URLRequest) throws -> URL {
  guard let url = request.url else {
    throw OpenCodeClientError.message("Request URL is missing")
  }
  return url
}

private func requestBodyData(_ request: URLRequest) throws -> Data {
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

private func makeStatusResponse(
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

private extension NSLock {
  func withLock<T>(_ body: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try body()
  }
}
