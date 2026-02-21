import OpenCodeNetworking
import XCTest

final class SSEParserTests: XCTestCase {
  func testParsesSingleMessage() {
    var parser = SSEParser()

    XCTAssertNil(parser.ingest(line: "event: message"))
    XCTAssertNil(parser.ingest(line: "data: {\"type\":\"server.connected\",\"properties\":{}}"))

    let output = parser.ingest(line: "")

    XCTAssertEqual(output?.event, "message")
    XCTAssertEqual(output?.data, "{\"type\":\"server.connected\",\"properties\":{}}")
    XCTAssertNil(output?.retry)
  }

  func testParsesMultilineData() {
    var parser = SSEParser()

    XCTAssertNil(parser.ingest(line: "data: hello"))
    XCTAssertNil(parser.ingest(line: "data: world"))

    let output = parser.ingest(line: "")
    XCTAssertEqual(output?.data, "hello\nworld")
  }

  func testParsesRetryAndID() {
    var parser = SSEParser()

    XCTAssertNil(parser.ingest(line: "id: evt-1"))
    XCTAssertNil(parser.ingest(line: "retry: 1500"))
    XCTAssertNil(parser.ingest(line: "data: ok"))

    let output = parser.ingest(line: "")
    XCTAssertEqual(output?.id, "evt-1")
    XCTAssertEqual(output?.retry, 1500)
    XCTAssertEqual(output?.data, "ok")
  }

  func testIgnoresInvalidRetry() {
    var parser = SSEParser()

    XCTAssertNil(parser.ingest(line: "retry: nope"))
    XCTAssertNil(parser.ingest(line: "data: hello"))

    let output = parser.ingest(line: "")
    XCTAssertNil(output?.retry)
    XCTAssertEqual(output?.data, "hello")
  }

  func testIgnoresCommentLines() {
    var parser = SSEParser()

    XCTAssertNil(parser.ingest(line: ": keep-alive"))
    XCTAssertNil(parser.ingest(line: "data: ping"))

    let output = parser.ingest(line: "")
    XCTAssertEqual(output?.data, "ping")
  }

  func testNormalizesCarriageReturn() {
    var parser = SSEParser()

    XCTAssertNil(parser.ingest(line: "data: hello\r"))

    let output = parser.ingest(line: "\r")
    XCTAssertEqual(output?.data, "hello")
  }

  func testFinishFlushesPendingMessage() {
    var parser = SSEParser()

    XCTAssertNil(parser.ingest(line: "event: message"))
    XCTAssertNil(parser.ingest(line: "data: tail"))

    let output = parser.finish()
    XCTAssertEqual(output?.event, "message")
    XCTAssertEqual(output?.data, "tail")
  }

  func testFlushesEventWithoutData() {
    var parser = SSEParser()

    XCTAssertNil(parser.ingest(line: "event: ping"))

    let output = parser.ingest(line: "")
    XCTAssertEqual(output?.event, "ping")
    XCTAssertNil(output?.data)
  }
}
