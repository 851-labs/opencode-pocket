import OpenCodeModels
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

  func testDecodesToolPartState() throws {
    let json = """
    {
      "id": "part_tool",
      "sessionID": "ses_123",
      "messageID": "msg_1",
      "type": "tool",
      "tool": "bash",
      "callID": "call_1",
      "state": {
        "status": "completed",
        "input": {
          "command": "ls",
          "description": "List files"
        },
        "output": "README.md",
        "title": "Lists files",
        "metadata": {},
        "time": {
          "start": 100,
          "end": 120
        }
      }
    }
    """.data(using: .utf8)!

    let part = try JSONDecoder().decode(MessagePart.self, from: json)

    XCTAssertEqual(part.type, "tool")
    XCTAssertEqual(part.tool, "bash")
    XCTAssertEqual(part.callID, "call_1")
    XCTAssertEqual(part.toolState?.status.rawValue, "completed")
    XCTAssertEqual(part.toolInputString("command"), "ls")
    XCTAssertEqual(part.toolState?.output, "README.md")
  }

  func testDecodesSessionStatusRetry() throws {
    let json = """
    {
      "type": "retry",
      "attempt": 2,
      "message": "Retrying",
      "next": 174000
    }
    """.data(using: .utf8)!

    let status = try JSONDecoder().decode(SessionStatus.self, from: json)

    XCTAssertEqual(status.type.rawValue, "retry")
    XCTAssertEqual(status.attempt, 2)
    XCTAssertEqual(status.message, "Retrying")
    XCTAssertEqual(status.next, 174_000)
    XCTAssertTrue(status.isRunning)
  }

  func testServerEventTypeMappingSupportsKnownAndUnknownEvents() {
    let known = ServerEvent(type: "message.part.updated", properties: .object([:]))
    XCTAssertEqual(known.eventType, .messagePartUpdated)

    let unknown = ServerEvent(type: "custom.event", properties: .object([:]))
    XCTAssertEqual(unknown.eventType, .unknown("custom.event"))
  }
}
