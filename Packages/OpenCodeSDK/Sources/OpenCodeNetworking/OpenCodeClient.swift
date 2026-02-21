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

  public func listSessions(directory: String? = nil) async throws -> [Session] {
    try await request(.get, path: "/session", query: mergedDirectoryQuery(directory), response: [Session].self)
  }

  public func listAgents(directory: String? = nil) async throws -> [AgentDescriptor] {
    try await request(.get, path: "/agent", query: mergedDirectoryQuery(directory), response: [AgentDescriptor].self)
  }

  public func listConfigProviders(directory: String? = nil) async throws -> ProviderCatalogResponse {
    try await request(.get, path: "/config/providers", query: mergedDirectoryQuery(directory), response: ProviderCatalogResponse.self)
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

  public func listMessages(sessionID: String, limit: Int? = nil, directory: String? = nil) async throws -> [MessageEnvelope] {
    var query = mergedDirectoryQuery(directory)
    if let limit {
      query.append(URLQueryItem(name: "limit", value: String(limit)))
    }
    return try await request(
      .get,
      path: "/session/\(escapedPathComponent(sessionID))/message",
      query: query,
      response: [MessageEnvelope].self
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

  public func subscribeEvents(directory: String? = nil) -> AsyncStream<ServerEvent> {
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
              path: "/event",
              method: .get,
              query: mergedDirectoryQuery(directory),
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
                continuation: continuation
              )
            }

            flushRemainingSSEBuffer(
              buffer: &buffer,
              parser: &parser,
              lastEventID: &lastEventID,
              retryDelayMilliseconds: &retryDelayMilliseconds,
              continuation: continuation
            )

            consume(
              parser.finish(),
              lastEventID: &lastEventID,
              retryDelayMilliseconds: &retryDelayMilliseconds,
              continuation: continuation
            )
          } catch {
            if Task.isCancelled {
              break
            }

            let backoffMilliseconds = min(
              Int(Double(retryDelayMilliseconds) * pow(2.0, Double(max(0, attempts - 1)))),
              30_000
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

  private func consume(
    _ message: SSEMessage?,
    lastEventID: inout String?,
    retryDelayMilliseconds: inout Int,
    continuation: AsyncStream<ServerEvent>.Continuation
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
      yieldEvent(from: data, to: continuation)
    }
  }

  private func flushBufferedSSEFrames(
    buffer: inout String,
    parser: inout SSEParser,
    lastEventID: inout String?,
    retryDelayMilliseconds: inout Int,
    continuation: AsyncStream<ServerEvent>.Continuation
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
        continuation: continuation
      )
    }
  }

  private func flushRemainingSSEBuffer(
    buffer: inout String,
    parser: inout SSEParser,
    lastEventID: inout String?,
    retryDelayMilliseconds: inout Int,
    continuation: AsyncStream<ServerEvent>.Continuation
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
      continuation: continuation
    )

    buffer = ""
  }

  private func flushFrame(
    _ frame: String,
    parser: inout SSEParser,
    lastEventID: inout String?,
    retryDelayMilliseconds: inout Int,
    continuation: AsyncStream<ServerEvent>.Continuation
  ) {
    for line in frame.split(separator: "\n", omittingEmptySubsequences: false) {
      _ = parser.ingest(line: String(line))
    }

    consume(
      parser.ingest(line: ""),
      lastEventID: &lastEventID,
      retryDelayMilliseconds: &retryDelayMilliseconds,
      continuation: continuation
    )
  }

  private func request<T: Decodable>(
    _ method: HTTPMethod,
    path: String,
    query: [URLQueryItem] = [],
    body: AnyEncodable? = nil,
    response type: T.Type
  ) async throws -> T {
    let bodyData = try encodeBody(body)
    let request = try requestBuilder.makeRequest(path: path, method: method, query: query, body: bodyData)

    do {
      let (data, response) = try await urlSession.data(for: request)
      let httpResponse = try validatedHTTPResponse(from: response)

      guard (200 ..< 300).contains(httpResponse.statusCode) else {
        throw parseHTTPError(code: httpResponse.statusCode, data: data)
      }

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

  private func requestNoContent(
    _ method: HTTPMethod,
    path: String,
    query: [URLQueryItem] = [],
    body: AnyEncodable? = nil
  ) async throws {
    let bodyData = try encodeBody(body)
    let request = try requestBuilder.makeRequest(path: path, method: method, query: query, body: bodyData)

    do {
      let (data, response) = try await urlSession.data(for: request)
      let httpResponse = try validatedHTTPResponse(from: response)

      guard (200 ..< 300).contains(httpResponse.statusCode) else {
        throw parseHTTPError(code: httpResponse.statusCode, data: data)
      }
    } catch let error as OpenCodeClientError {
      throw error
    } catch {
      throw OpenCodeClientError.transport(error)
    }
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

  private func yieldEvent(from data: String, to continuation: AsyncStream<ServerEvent>.Continuation) {
    let payload = data.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !payload.isEmpty else { return }

    if let event = try? JSONDecoder().decode(ServerEvent.self, from: Data(payload.utf8)) {
      continuation.yield(event)
      return
    }

    continuation.yield(
      ServerEvent(
        type: "event.decode.error",
        properties: .object([
          "raw": .string(payload),
        ])
      )
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
