@testable import OpenCodePocket
import XCTest

final class SSEParserTests: XCTestCase {
  func testParsesSingleMessage() {
    var parser = SSEParser()

    XCTAssertNil(parser.ingest(line: "event: message"))
    XCTAssertNil(parser.ingest(line: "data: {\"type\":\"server.connected\",\"properties\":{}}"))

    let output = parser.ingest(line: "")

    XCTAssertEqual(output?.event, "message")
    XCTAssertEqual(output?.data, "{\"type\":\"server.connected\",\"properties\":{}}")
  }

  func testParsesMultilineData() {
    var parser = SSEParser()

    XCTAssertNil(parser.ingest(line: "data: hello"))
    XCTAssertNil(parser.ingest(line: "data: world"))

    let output = parser.ingest(line: "")
    XCTAssertEqual(output?.data, "hello\nworld")
  }
}
