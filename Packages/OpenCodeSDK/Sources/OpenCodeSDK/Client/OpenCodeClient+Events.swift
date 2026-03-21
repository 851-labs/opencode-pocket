import Foundation

public extension OpenCodeClient {
  func subscribeEvents(directory: String? = nil) -> AsyncStream<ServerEvent> {
    subscribeSSE(path: "/event", query: mergedDirectoryQuery(directory)) { payload in
      Self.decodeServerEvent(from: payload)
    }
  }

  func subscribeGlobalEvents() -> AsyncStream<GlobalServerEvent> {
    subscribeSSE(path: "/global/event") { payload in
      Self.decodeGlobalEvent(from: payload)
    }
  }
}

extension OpenCodeClient {
  private func subscribeSSE<Event: Sendable>(
    path: String,
    query: [URLQueryItem] = [],
    decode: @escaping @Sendable (String) -> Event
  ) -> AsyncStream<Event> {
    AsyncStream { continuation in
      let requestBuilder = requestBuilder
      let urlSession = urlSession
      let task = Task.detached(priority: Task.currentPriority) {
        await Self.runSSELoop(
          requestBuilder: requestBuilder,
          urlSession: urlSession,
          path: path,
          query: query,
          continuation: continuation,
          decode: decode
        )
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  private static func runSSELoop<Event: Sendable>(
    requestBuilder: HTTPRequestBuilder,
    urlSession: URLSession,
    path: String,
    query: [URLQueryItem],
    continuation: AsyncStream<Event>.Continuation,
    decode: @escaping @Sendable (String) -> Event
  ) async {
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

  private static func consume<Event>(
    _ message: SSEMessage?,
    lastEventID: inout String?,
    retryDelayMilliseconds: inout Int,
    continuation: AsyncStream<Event>.Continuation,
    decode: @Sendable (String) -> Event
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

  private static func flushBufferedSSEFrames<Event>(
    buffer: inout String,
    parser: inout SSEParser,
    lastEventID: inout String?,
    retryDelayMilliseconds: inout Int,
    continuation: AsyncStream<Event>.Continuation,
    decode: @Sendable (String) -> Event
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

  private static func flushRemainingSSEBuffer<Event>(
    buffer: inout String,
    parser: inout SSEParser,
    lastEventID: inout String?,
    retryDelayMilliseconds: inout Int,
    continuation: AsyncStream<Event>.Continuation,
    decode: @Sendable (String) -> Event
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

  private static func flushFrame<Event>(
    _ frame: String,
    parser: inout SSEParser,
    lastEventID: inout String?,
    retryDelayMilliseconds: inout Int,
    continuation: AsyncStream<Event>.Continuation,
    decode: @Sendable (String) -> Event
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
