@testable import OpenCodePocket
import XCTest

final class JSONDecodingTests: XCTestCase {
  func testDecodesSession() throws {
    let json = """
    {
      "id": "ses_123",
      "slug": "session-slug",
      "projectID": "prj_1",
      "directory": "/tmp/project",
      "title": "My Session",
      "version": "1",
      "time": {
        "created": 123,
        "updated": 456
      }
    }
    """.data(using: .utf8)!

    let session = try JSONDecoder().decode(Session.self, from: json)

    XCTAssertEqual(session.id, "ses_123")
    XCTAssertEqual(session.title, "My Session")
    XCTAssertEqual(session.time.created, 123)
    XCTAssertEqual(session.time.updated, 456)
  }

  func testDecodesMessageEnvelopeAndRendersText() throws {
    let json = """
    {
      "info": {
        "id": "msg_1",
        "sessionID": "ses_123",
        "role": "assistant",
        "time": { "created": 999 },
        "parentID": "msg_0",
        "modelID": "claude-sonnet",
        "providerID": "anthropic",
        "mode": "build",
        "agent": "build",
        "path": {},
        "cost": 0,
        "tokens": {}
      },
      "parts": [
        {
          "id": "part_1",
          "sessionID": "ses_123",
          "messageID": "msg_1",
          "type": "text",
          "text": "Hello from assistant"
        }
      ]
    }
    """.data(using: .utf8)!

    let envelope = try JSONDecoder().decode(MessageEnvelope.self, from: json)

    XCTAssertEqual(envelope.id, "msg_1")
    XCTAssertEqual(envelope.info.role, .assistant)
    XCTAssertEqual(envelope.textBody, "Hello from assistant")
  }
}
