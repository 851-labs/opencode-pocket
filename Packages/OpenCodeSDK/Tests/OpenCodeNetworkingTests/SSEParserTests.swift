import OpenCodeNetworking
import Testing

@Suite(.tags(.networking))
struct SSEParserTests {
  @Test func parsesSingleMessage() {
    var parser = SSEParser()

    #expect(parser.ingest(line: "event: message") == nil)
    #expect(parser.ingest(line: "data: {\"type\":\"server.connected\",\"properties\":{}}") == nil)

    let output = parser.ingest(line: "")

    #expect(output?.event == "message")
    #expect(output?.data == "{\"type\":\"server.connected\",\"properties\":{}}")
    #expect(output?.retry == nil)
  }

  @Test func parsesMultilineData() {
    var parser = SSEParser()

    #expect(parser.ingest(line: "data: hello") == nil)
    #expect(parser.ingest(line: "data: world") == nil)

    let output = parser.ingest(line: "")
    #expect(output?.data == "hello\nworld")
  }

  @Test func parsesRetryAndID() {
    var parser = SSEParser()

    #expect(parser.ingest(line: "id: evt-1") == nil)
    #expect(parser.ingest(line: "retry: 1500") == nil)
    #expect(parser.ingest(line: "data: ok") == nil)

    let output = parser.ingest(line: "")
    #expect(output?.id == "evt-1")
    #expect(output?.retry == 1500)
    #expect(output?.data == "ok")
  }

  @Test func ignoresInvalidRetry() {
    var parser = SSEParser()

    #expect(parser.ingest(line: "retry: nope") == nil)
    #expect(parser.ingest(line: "data: hello") == nil)

    let output = parser.ingest(line: "")
    #expect(output?.retry == nil)
    #expect(output?.data == "hello")
  }

  @Test func ignoresCommentLines() {
    var parser = SSEParser()

    #expect(parser.ingest(line: ": keep-alive") == nil)
    #expect(parser.ingest(line: "data: ping") == nil)

    let output = parser.ingest(line: "")
    #expect(output?.data == "ping")
  }

  @Test func normalizesCarriageReturn() {
    var parser = SSEParser()

    #expect(parser.ingest(line: "data: hello\r") == nil)

    let output = parser.ingest(line: "\r")
    #expect(output?.data == "hello")
  }

  @Test func finishFlushesPendingMessage() {
    var parser = SSEParser()

    #expect(parser.ingest(line: "event: message") == nil)
    #expect(parser.ingest(line: "data: tail") == nil)

    let output = parser.finish()
    #expect(output?.event == "message")
    #expect(output?.data == "tail")
  }

  @Test func flushesEventWithoutData() {
    var parser = SSEParser()

    #expect(parser.ingest(line: "event: ping") == nil)

    let output = parser.ingest(line: "")
    #expect(output?.event == "ping")
    #expect(output?.data == nil)
  }
}
