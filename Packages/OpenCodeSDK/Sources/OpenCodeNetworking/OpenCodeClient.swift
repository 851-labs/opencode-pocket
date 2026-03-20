import Foundation
import OpenCodeModels

public struct OpenCodeClientConfiguration: Sendable {
  public let baseURL: URL
  public let username: String?
  public let password: String?
  public let directory: String?

  public init(baseURL: URL, username: String?, password: String?, directory: String?) {
    self.baseURL = baseURL
    self.username = username
    self.password = password
    self.directory = directory
  }
}

public final class OpenCodeClient {
  private let configuration: OpenCodeClientConfiguration
  private let requestBuilder: HTTPRequestBuilder
  private let urlSession: URLSession

  public init(configuration: OpenCodeClientConfiguration, urlSession: URLSession = .shared) {
    self.configuration = configuration
    requestBuilder = HTTPRequestBuilder(
      baseURL: configuration.baseURL,
      username: configuration.username,
      password: configuration.password
    )
    self.urlSession = urlSession
  }

  public func health() async throws -> HealthResponse {
    try await request(.get, path: "/global/health", response: HealthResponse.self)
  }

  public func getGlobalConfig() async throws -> OpenCodeConfig {
    try await request(.get, path: "/global/config", response: OpenCodeConfig.self)
  }

  public func getConfig(directory: String? = nil) async throws -> OpenCodeConfig {
    try await request(.get, path: "/config", query: mergedDirectoryQuery(directory), response: OpenCodeConfig.self)
  }

  public func getPath() async throws -> PathInfo {
    try await request(.get, path: "/path", response: PathInfo.self)
  }

  public func listProjects() async throws -> [ProjectInfo] {
    try await request(.get, path: "/project", response: [ProjectInfo].self)
  }

  public func getCurrentProject(directory: String? = nil) async throws -> ProjectInfo {
    try await request(.get, path: "/project/current", query: mergedDirectoryQuery(directory), response: ProjectInfo.self)
  }

  public func listProviders(directory: String? = nil) async throws -> ProviderListResponse {
    try await request(.get, path: "/provider", query: mergedDirectoryQuery(directory), response: ProviderListResponse.self)
  }

  public func listProviderAuthMethods(directory: String? = nil) async throws -> ProviderAuthMethodResponse {
    try await request(.get, path: "/provider/auth", query: mergedDirectoryQuery(directory), response: ProviderAuthMethodResponse.self)
  }

  public func listFiles(path: String, directory: String? = nil) async throws -> [FileNode] {
    var queryItems = mergedDirectoryQuery(directory)
    queryItems.append(URLQueryItem(name: "path", value: path))
    return try await request(.get, path: "/file", query: queryItems, response: [FileNode].self)
  }

  public func readFile(path: String, directory: String? = nil) async throws -> FileContent {
    var queryItems = mergedDirectoryQuery(directory)
    queryItems.append(URLQueryItem(name: "path", value: path))
    return try await request(.get, path: "/file/content", query: queryItems, response: FileContent.self)
  }

  public func listFileStatus(directory: String? = nil) async throws -> [FileStatusEntry] {
    try await request(.get, path: "/file/status", query: mergedDirectoryQuery(directory), response: [FileStatusEntry].self)
  }

  public func getVCSInfo(directory: String? = nil) async throws -> VCSInfo {
    try await request(.get, path: "/vcs", query: mergedDirectoryQuery(directory), response: VCSInfo.self)
  }

  public func findFiles(
    query searchQuery: String,
    includeDirectories: Bool? = nil,
    type: FileNodeType? = nil,
    limit: Int? = nil,
    directory: String? = nil
  ) async throws -> [String] {
    var queryItems = mergedDirectoryQuery(directory)
    queryItems.append(URLQueryItem(name: "query", value: searchQuery))
    if let includeDirectories {
      queryItems.append(URLQueryItem(name: "dirs", value: includeDirectories ? "true" : "false"))
    }
    if let type {
      queryItems.append(URLQueryItem(name: "type", value: type.rawValue))
    }
    if let limit {
      queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
    }

    return try await request(.get, path: "/find/file", query: queryItems, response: [String].self)
  }

  public func listSessions(
    directory: String? = nil,
    roots: Bool? = nil,
    start: Double? = nil,
    search: String? = nil,
    limit: Int? = nil
  ) async throws -> [Session] {
    var query = mergedDirectoryQuery(directory)
    if let roots {
      query.append(URLQueryItem(name: "roots", value: roots ? "true" : "false"))
    }
    if let start {
      query.append(URLQueryItem(name: "start", value: String(start)))
    }
    if let search, !search.isEmpty {
      query.append(URLQueryItem(name: "search", value: search))
    }
    if let limit {
      query.append(URLQueryItem(name: "limit", value: String(limit)))
    }

    return try await request(.get, path: "/session", query: query, response: [Session].self)
  }

  public func listSessionStatuses() async throws -> [String: SessionStatus] {
    try await request(.get, path: "/session/status", response: [String: SessionStatus].self)
  }

  public func listAgents(directory: String? = nil) async throws -> [AgentDescriptor] {
    try await request(.get, path: "/agent", query: mergedDirectoryQuery(directory), response: [AgentDescriptor].self)
  }

  public func listConfigProviders(directory: String? = nil) async throws -> ProviderCatalogResponse {
    try await request(.get, path: "/config/providers", query: mergedDirectoryQuery(directory), response: ProviderCatalogResponse.self)
  }

  public func listLSPStatus(directory: String? = nil) async throws -> [LSPServerStatus] {
    try await request(.get, path: "/lsp", query: mergedDirectoryQuery(directory), response: [LSPServerStatus].self)
  }

  public func listMCPStatus(directory: String? = nil) async throws -> [String: MCPServerStatus] {
    try await request(.get, path: "/mcp", query: mergedDirectoryQuery(directory), response: [String: MCPServerStatus].self)
  }

  public func createSession(_ body: SessionCreateRequest, directory: String? = nil) async throws -> Session {
    try await request(
      .post,
      path: "/session",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(body),
      response: Session.self
    )
  }

  public func getSession(id: String, directory: String? = nil) async throws -> Session {
    try await request(
      .get,
      path: "/session/\(escapedPathComponent(id))",
      query: mergedDirectoryQuery(directory),
      response: Session.self
    )
  }

  public func updateSession(id: String, body: SessionUpdateRequest, directory: String? = nil) async throws -> Session {
    try await request(
      .patch,
      path: "/session/\(escapedPathComponent(id))",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(body),
      response: Session.self
    )
  }

  public func deleteSession(id: String, directory: String? = nil) async throws -> Bool {
    try await request(
      .delete,
      path: "/session/\(escapedPathComponent(id))",
      query: mergedDirectoryQuery(directory),
      response: Bool.self
    )
  }

  public func listMessages(
    sessionID: String,
    limit: Int? = nil,
    before: String? = nil,
    directory: String? = nil
  ) async throws -> [MessageEnvelope] {
    let page = try await listMessagesPage(sessionID: sessionID, limit: limit, before: before, directory: directory)
    return page.items
  }

  public func listMessagesPage(
    sessionID: String,
    limit: Int? = nil,
    before: String? = nil,
    directory: String? = nil
  ) async throws -> OpenCodePage<MessageEnvelope> {
    var query = mergedDirectoryQuery(directory)
    if let limit {
      query.append(URLQueryItem(name: "limit", value: String(limit)))
    }

    if let before, !before.isEmpty {
      query.append(URLQueryItem(name: "before", value: before))
    }

    return try await requestPage(
      .get,
      path: "/session/\(escapedPathComponent(sessionID))/message",
      query: query,
      response: MessageEnvelope.self
    )
  }

  public func getMessage(sessionID: String, messageID: String, directory: String? = nil) async throws -> MessageEnvelope {
    try await request(
      .get,
      path: "/session/\(escapedPathComponent(sessionID))/message/\(escapedPathComponent(messageID))",
      query: mergedDirectoryQuery(directory),
      response: MessageEnvelope.self
    )
  }

  public func getSessionDiff(sessionID: String, messageID: String? = nil, directory: String? = nil) async throws -> [FileDiff] {
    var query = mergedDirectoryQuery(directory)
    if let messageID {
      query.append(URLQueryItem(name: "messageID", value: messageID))
    }

    return try await request(
      .get,
      path: "/session/\(escapedPathComponent(sessionID))/diff",
      query: query,
      response: [FileDiff].self
    )
  }

  public func getSessionTodo(sessionID: String, directory: String? = nil) async throws -> [TodoItem] {
    try await request(
      .get,
      path: "/session/\(escapedPathComponent(sessionID))/todo",
      query: mergedDirectoryQuery(directory),
      response: [TodoItem].self
    )
  }

  public func sendMessage(sessionID: String, body: PromptRequest, directory: String? = nil) async throws -> MessageEnvelope {
    try await request(
      .post,
      path: "/session/\(escapedPathComponent(sessionID))/message",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(body),
      response: MessageEnvelope.self
    )
  }

  public func sendMessageAsync(sessionID: String, body: PromptRequest, directory: String? = nil) async throws {
    try await requestNoContent(
      .post,
      path: "/session/\(escapedPathComponent(sessionID))/prompt_async",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(body)
    )
  }

  public func abortSession(sessionID: String, directory: String? = nil) async throws -> Bool {
    try await request(
      .post,
      path: "/session/\(escapedPathComponent(sessionID))/abort",
      query: mergedDirectoryQuery(directory),
      response: Bool.self
    )
  }

  public func listPermissions(directory: String? = nil) async throws -> [OpenCodeModels.PermissionRequest] {
    try await request(
      .get,
      path: "/permission",
      query: mergedDirectoryQuery(directory),
      response: [OpenCodeModels.PermissionRequest].self
    )
  }

  public func replyPermission(
    requestID: String,
    reply: OpenCodeModels.PermissionReply,
    message: String? = nil,
    directory: String? = nil
  ) async throws -> Bool {
    try await respondPermission(requestID: requestID, response: reply, message: message, directory: directory)
  }

  public func respondPermission(
    requestID: String,
    response: OpenCodeModels.PermissionReply,
    message: String? = nil,
    directory: String? = nil
  ) async throws -> Bool {
    try await request(
      .post,
      path: "/permission/\(escapedPathComponent(requestID))/reply",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(OpenCodeModels.PermissionReplyRequest(reply: response, message: message)),
      response: Bool.self
    )
  }

  public func listQuestions(directory: String? = nil) async throws -> [OpenCodeModels.QuestionRequest] {
    try await request(
      .get,
      path: "/question",
      query: mergedDirectoryQuery(directory),
      response: [OpenCodeModels.QuestionRequest].self
    )
  }

  public func replyQuestion(
    requestID: String,
    answers: [OpenCodeModels.QuestionAnswer],
    directory: String? = nil
  ) async throws -> Bool {
    try await request(
      .post,
      path: "/question/\(escapedPathComponent(requestID))/reply",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(OpenCodeModels.QuestionReplyRequest(answers: answers)),
      response: Bool.self
    )
  }

  public func rejectQuestion(requestID: String, directory: String? = nil) async throws -> Bool {
    try await request(
      .post,
      path: "/question/\(escapedPathComponent(requestID))/reject",
      query: mergedDirectoryQuery(directory),
      response: Bool.self
    )
  }

  public func subscribeEvents(directory: String? = nil) -> AsyncStream<ServerEvent> {
    subscribeSSE(path: "/event", query: mergedDirectoryQuery(directory), decode: Self.decodeServerEvent)
  }

  public func subscribeGlobalEvents() -> AsyncStream<GlobalServerEvent> {
    subscribeSSE(path: "/global/event", decode: Self.decodeGlobalEvent)
  }

  private func subscribeSSE<Event: Sendable>(
    path: String,
    query: [URLQueryItem] = [],
    decode: @escaping (String) -> Event
  ) -> AsyncStream<Event> {
    AsyncStream { continuation in
      let task = Task {
        var attempts = 0
        var lastEventID: String?
        var retryDelayMilliseconds = 3000

        while !Task.isCancelled {
          attempts += 1

          do {
            var headers = [
              "Accept": "text/event-stream",
            ]

            if let lastEventID {
              headers["Last-Event-ID"] = lastEventID
            }

            let request = try requestBuilder.makeRequest(
              path: path,
              method: .get,
              query: query,
              timeout: 600,
              headers: headers
            )

            let (bytes, response) = try await urlSession.bytes(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
              throw OpenCodeClientError.invalidResponse
            }
            guard (200 ..< 300).contains(httpResponse.statusCode) else {
              throw OpenCodeClientError.httpStatus(code: httpResponse.statusCode, message: "Unable to subscribe to event stream")
            }

            attempts = 0
            var parser = SSEParser()

            var buffer = ""
            for try await byte in bytes {
              if Task.isCancelled { break }
              buffer.unicodeScalars.append(Unicode.Scalar(byte))
              flushBufferedSSEFrames(
                buffer: &buffer,
                parser: &parser,
                lastEventID: &lastEventID,
                retryDelayMilliseconds: &retryDelayMilliseconds,
                continuation: continuation,
                decode: decode
              )
            }

            flushRemainingSSEBuffer(
              buffer: &buffer,
              parser: &parser,
              lastEventID: &lastEventID,
              retryDelayMilliseconds: &retryDelayMilliseconds,
              continuation: continuation,
              decode: decode
            )

            consume(
              parser.finish(),
              lastEventID: &lastEventID,
              retryDelayMilliseconds: &retryDelayMilliseconds,
              continuation: continuation,
              decode: decode
            )
          } catch {
            if Task.isCancelled {
              break
            }

            let backoffMilliseconds = min(
              Int(Double(retryDelayMilliseconds) * pow(2.0, Double(max(0, attempts - 1)))),
              30000
            )

            try? await Task.sleep(nanoseconds: UInt64(backoffMilliseconds) * 1_000_000)
          }
        }

        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  private func consume<Event>(
    _ message: SSEMessage?,
    lastEventID: inout String?,
    retryDelayMilliseconds: inout Int,
    continuation: AsyncStream<Event>.Continuation,
    decode: (String) -> Event
  ) {
    guard let message else {
      return
    }

    if let id = message.id {
      lastEventID = id
    }

    if let retry = message.retry {
      retryDelayMilliseconds = retry
    }

    if let data = message.data {
      let payload = data.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !payload.isEmpty else { return }
      continuation.yield(decode(payload))
    }
  }

  private func flushBufferedSSEFrames<Event>(
    buffer: inout String,
    parser: inout SSEParser,
    lastEventID: inout String?,
    retryDelayMilliseconds: inout Int,
    continuation: AsyncStream<Event>.Continuation,
    decode: (String) -> Event
  ) {
    let normalized = buffer
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")

    var frames = normalized.components(separatedBy: "\n\n")
    guard frames.count > 1 else {
      buffer = normalized
      return
    }

    buffer = frames.removeLast()

    for frame in frames {
      flushFrame(
        frame,
        parser: &parser,
        lastEventID: &lastEventID,
        retryDelayMilliseconds: &retryDelayMilliseconds,
        continuation: continuation,
        decode: decode
      )
    }
  }

  private func flushRemainingSSEBuffer<Event>(
    buffer: inout String,
    parser: inout SSEParser,
    lastEventID: inout String?,
    retryDelayMilliseconds: inout Int,
    continuation: AsyncStream<Event>.Continuation,
    decode: (String) -> Event
  ) {
    let normalized = buffer
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")

    guard !normalized.isEmpty else {
      buffer = ""
      return
    }

    flushFrame(
      normalized,
      parser: &parser,
      lastEventID: &lastEventID,
      retryDelayMilliseconds: &retryDelayMilliseconds,
      continuation: continuation,
      decode: decode
    )

    buffer = ""
  }

  private func flushFrame<Event>(
    _ frame: String,
    parser: inout SSEParser,
    lastEventID: inout String?,
    retryDelayMilliseconds: inout Int,
    continuation: AsyncStream<Event>.Continuation,
    decode: (String) -> Event
  ) {
    for line in frame.split(separator: "\n", omittingEmptySubsequences: false) {
      _ = parser.ingest(line: String(line))
    }

    consume(
      parser.ingest(line: ""),
      lastEventID: &lastEventID,
      retryDelayMilliseconds: &retryDelayMilliseconds,
      continuation: continuation,
      decode: decode
    )
  }

  private func request<T: Decodable>(
    _ method: HTTPMethod,
    path: String,
    query: [URLQueryItem] = [],
    body: AnyEncodable? = nil,
    response type: T.Type
  ) async throws -> T {
    do {
      let (data, _) = try await performRequest(method, path: path, query: query, body: body)

      do {
        return try JSONDecoder().decode(type, from: data)
      } catch {
        throw OpenCodeClientError.decoding(error)
      }
    } catch let error as OpenCodeClientError {
      throw error
    } catch {
      throw OpenCodeClientError.transport(error)
    }
  }

  private func requestPage<T: Decodable & Sendable>(
    _ method: HTTPMethod,
    path: String,
    query: [URLQueryItem] = [],
    body: AnyEncodable? = nil,
    response type: T.Type
  ) async throws -> OpenCodePage<T> {
    do {
      let (data, response) = try await performRequest(method, path: path, query: query, body: body)

      do {
        let items = try JSONDecoder().decode([T].self, from: data)
        return OpenCodePage(
          items: items,
          nextCursor: response.value(forHTTPHeaderField: "X-Next-Cursor")?.trimmedNonEmpty,
          nextURL: parseNextURL(from: response.value(forHTTPHeaderField: "Link"))
        )
      } catch {
        throw OpenCodeClientError.decoding(error)
      }
    } catch let error as OpenCodeClientError {
      throw error
    } catch {
      throw OpenCodeClientError.transport(error)
    }
  }

  private func requestNoContent(
    _ method: HTTPMethod,
    path: String,
    query: [URLQueryItem] = [],
    body: AnyEncodable? = nil
  ) async throws {
    do {
      _ = try await performRequest(method, path: path, query: query, body: body)
    } catch let error as OpenCodeClientError {
      throw error
    } catch {
      throw OpenCodeClientError.transport(error)
    }
  }

  private func performRequest(
    _ method: HTTPMethod,
    path: String,
    query: [URLQueryItem] = [],
    body: AnyEncodable? = nil,
    headers: [String: String] = [:]
  ) async throws -> (Data, HTTPURLResponse) {
    let bodyData = try encodeBody(body)
    let request = try requestBuilder.makeRequest(path: path, method: method, query: query, body: bodyData, headers: headers)
    let (data, response) = try await urlSession.data(for: request)
    let httpResponse = try validatedHTTPResponse(from: response)

    guard (200 ..< 300).contains(httpResponse.statusCode) else {
      throw parseHTTPError(code: httpResponse.statusCode, data: data)
    }

    return (data, httpResponse)
  }

  private func validatedHTTPResponse(from response: URLResponse) throws -> HTTPURLResponse {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw OpenCodeClientError.invalidResponse
    }
    return httpResponse
  }

  private func encodeBody(_ body: AnyEncodable?) throws -> Data? {
    guard let body else { return nil }
    do {
      return try JSONEncoder().encode(body)
    } catch {
      throw OpenCodeClientError.message("Failed to encode request body: \(error.localizedDescription)")
    }
  }

  private func parseHTTPError(code: Int, data: Data) -> OpenCodeClientError {
    if let notFound = try? JSONDecoder().decode(APINotFoundEnvelope.self, from: data) {
      let message = notFound.data.message ?? "Not found"
      return .httpStatus(code: code, message: message)
    }

    if let badRequest = try? JSONDecoder().decode(APIBadRequestEnvelope.self, from: data) {
      if let firstError = badRequest.errors?.first {
        return .httpStatus(code: code, message: firstError.compactDescription)
      }
      return .httpStatus(code: code, message: badRequest.data?.compactDescription)
    }

    if let raw = String(data: data, encoding: .utf8), !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return .httpStatus(code: code, message: raw)
    }

    return .httpStatus(code: code, message: nil)
  }

  private func escapedPathComponent(_ value: String) -> String {
    value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
  }

  private func mergedDirectoryQuery(_ override: String?) -> [URLQueryItem] {
    let resolved = (override?.trimmedNonEmpty) ?? configuration.directory?.trimmedNonEmpty
    guard let resolved else {
      return []
    }
    return [URLQueryItem(name: "directory", value: resolved)]
  }

  private func parseNextURL(from linkHeader: String?) -> URL? {
    guard let linkHeader else {
      return nil
    }

    for item in linkHeader.split(separator: ",") {
      let value = String(item).trimmingCharacters(in: .whitespacesAndNewlines)
      guard value.contains("rel=\"next\"") else { continue }
      guard let start = value.firstIndex(of: "<"), let end = value.firstIndex(of: ">") else { continue }
      return URL(string: String(value[value.index(after: start) ..< end]))
    }

    return nil
  }

  private static func decodeServerEvent(from payload: String) -> ServerEvent {
    if let event = try? JSONDecoder().decode(ServerEvent.self, from: Data(payload.utf8)) {
      return event
    }

    return makeDecodeErrorEvent(raw: payload)
  }

  private static func decodeGlobalEvent(from payload: String) -> GlobalServerEvent {
    if let event = try? JSONDecoder().decode(GlobalServerEvent.self, from: Data(payload.utf8)) {
      return event
    }

    return GlobalServerEvent(directory: nil, payload: makeDecodeErrorEvent(raw: payload))
  }

  private static func makeDecodeErrorEvent(raw: String) -> ServerEvent {
    ServerEvent(
      type: "event.decode.error",
      properties: .object([
        "raw": .string(raw),
      ])
    )
  }
}

private struct AnyEncodable: Encodable {
  private let encodeBlock: (Encoder) throws -> Void

  init<T: Encodable>(_ value: T) {
    encodeBlock = value.encode(to:)
  }

  func encode(to encoder: Encoder) throws {
    try encodeBlock(encoder)
  }
}

private extension String {
  var trimmedNonEmpty: String? {
    let value = trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? nil : value
  }
}
