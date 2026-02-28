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
    XCTAssertEqual(envelope.info.cost, 0)
    XCTAssertEqual(envelope.info.tokenUsage?.output, 0)
    XCTAssertEqual(envelope.textBody, "Hello from assistant")
  }

  func testDecodesMessageTokenUsageWithSparseFields() throws {
    let json = """
    {
      "input": 120,
      "output": 55,
      "cache": {
        "read": 10
      }
    }
    """.data(using: .utf8)!

    let usage = try JSONDecoder().decode(MessageTokenUsage.self, from: json)

    XCTAssertEqual(usage.input, 120)
    XCTAssertEqual(usage.output, 55)
    XCTAssertEqual(usage.reasoning, 0)
    XCTAssertEqual(usage.cache.read, 10)
    XCTAssertEqual(usage.cache.write, 0)
    XCTAssertEqual(usage.contextUsageTotal, 185)
  }

  func testDecodesProviderModelContextLimit() throws {
    let json = """
    {
      "providers": [
        {
          "id": "openai",
          "name": "OpenAI",
          "models": {
            "gpt-5": {
              "id": "gpt-5",
              "providerID": "openai",
              "name": "GPT-5",
              "variants": {
                "high": {}
              },
              "limit": {
                "context": 272000,
                "input": 272000,
                "output": 32000
              }
            }
          }
        }
      ],
      "default": {
        "openai": "gpt-5"
      }
    }
    """.data(using: .utf8)!

    let response = try JSONDecoder().decode(ProviderCatalogResponse.self, from: json)

    XCTAssertEqual(response.providers.first?.models["gpt-5"]?.limit?.context, 272_000)
    XCTAssertEqual(response.providers.first?.models["gpt-5"]?.limit?.output, 32_000)
  }

  func testDecodesLSPAndMCPStatusPayloads() throws {
    let lspJSON = """
    [
      {
        "id": "sourcekit-lsp",
        "name": "sourcekit-lsp",
        "root": "Packages/OpenCodeSDK",
        "status": "connected"
      }
    ]
    """.data(using: .utf8)!

    let mcpJSON = """
    {
      "github": { "status": "connected" },
      "linear": { "status": "needs_auth" },
      "legacy": { "status": "other" }
    }
    """.data(using: .utf8)!

    let lsp = try JSONDecoder().decode([LSPServerStatus].self, from: lspJSON)
    let mcp = try JSONDecoder().decode([String: MCPServerStatus].self, from: mcpJSON)

    XCTAssertEqual(lsp.first?.status, .connected)
    XCTAssertEqual(mcp["github"]?.status, .connected)
    XCTAssertEqual(mcp["linear"]?.status, .needsAuth)
    XCTAssertEqual(mcp["legacy"]?.status, .unknown("other"))
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

    let lsp = ServerEvent(type: "lsp.updated", properties: .object([:]))
    XCTAssertEqual(lsp.eventType, .lspUpdated)

    let mcp = ServerEvent(type: "mcp.tools.changed", properties: .object([:]))
    XCTAssertEqual(mcp.eventType, .mcpToolsChanged)

    let unknown = ServerEvent(type: "custom.event", properties: .object([:]))
    XCTAssertEqual(unknown.eventType, .unknown("custom.event"))
  }
}
