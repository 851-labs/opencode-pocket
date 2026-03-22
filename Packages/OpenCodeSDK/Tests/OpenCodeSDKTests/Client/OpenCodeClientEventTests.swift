import Foundation
import OpenCodeSDK
import Testing

@Suite(.tags(.networking))
struct OpenCodeClientEventTests {
  @Test func subscribeEventsParsesStreamReconnectsAndSendsLastEventID() async {
    let responses = LockedResponses([
      (200, "id: evt-1\ndata: {\"type\":\"server.connected\",\"properties\":{}}\n\ndata: invalid-json\n\n"),
      (200, "retry: 5\ndata: {\"type\":\"server.heartbeat\",\"properties\":{}}\n\n"),
    ])

    let controller = URLProtocolStubController { request in
      let lastEventID = request.value(forHTTPHeaderField: "Last-Event-ID")
      let response = responses.next(lastEventID: lastEventID)
      return try makeStatusResponse(request: request, code: response.code, body: Data(response.body.utf8), headers: ["Content-Type": "text/event-stream"])
    }

    let client = makeClient(controller: controller)
    let stream = client.subscribeEvents()
    var iterator = stream.makeAsyncIterator()

    var received: [ServerEvent] = []
    for _ in 0..<3 {
      if let event = await iterator.next() {
        received.append(event)
      }
    }

    #expect(received.map(\.type) == ["server.connected", "event.decode.error", "server.heartbeat"])
    #expect(controller.recordedRequests.count >= 2)
    #expect(controller.recordedRequests.dropFirst().first?.value(forHTTPHeaderField: "Last-Event-ID") == "evt-1")
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
        body: Data("data:    \n\ndata: {\"type\":\"server.connected\",\"properties\":{}}\n\n".utf8)
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

  @Test(.timeLimit(.minutes(1)))
  func subscribeEventsCancelsDuringRetryBackoff() async {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(request: request, code: 503, body: Data())
    }

    let client = makeClient(controller: controller)
    let stream = client.subscribeEvents()

    let consumer = Task {
      var iterator = stream.makeAsyncIterator()
      _ = await iterator.next()
    }

    await controller.waitForFirstRequest()
    consumer.cancel()
    _ = await consumer.result

    #expect(controller.recordedRequests.count == 1)
  }
}

private final class LockedResponses: @unchecked Sendable {
  private let lock = NSLock()
  private var responses: [(Int, String)]
  private var lastEventIDs: [String?] = []

  init(_ responses: [(Int, String)]) {
    self.responses = responses
  }

  func next(lastEventID: String?) -> (code: Int, body: String) {
    lock.withLock {
      lastEventIDs.append(lastEventID)
      let next = responses.removeFirst()
      return (next.0, next.1)
    }
  }
}
