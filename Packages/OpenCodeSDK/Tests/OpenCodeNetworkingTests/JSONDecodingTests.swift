import Foundation
import OpenCodeModels
import Testing

@Suite(.tags(.networking))
struct JSONDecodingTests {
  @Test func decodesSession() throws {
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

    #expect(session.id == "ses_123")
    #expect(session.title == "My Session")
    #expect(session.time.created == 123)
    #expect(session.time.updated == 456)
  }

  @Test func decodesMessageEnvelopeAndRendersText() throws {
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

    #expect(envelope.id == "msg_1")
    #expect(envelope.info.role == .assistant)
    #expect(envelope.info.cost == 0)
    #expect(envelope.info.tokenUsage?.output == 0)
    #expect(envelope.textBody == "Hello from assistant")
  }

  @Test func decodesMessageTokenUsageWithSparseFields() throws {
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

    #expect(usage.input == 120)
    #expect(usage.output == 55)
    #expect(usage.reasoning == 0)
    #expect(usage.cache.read == 10)
    #expect(usage.cache.write == 0)
    #expect(usage.contextUsageTotal == 185)
  }

  @Test func decodesProviderModelContextLimit() throws {
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
    let provider = try #require(response.providers.first)

    #expect(provider.models["gpt-5"]?.limit?.context == 272_000)
    #expect(provider.models["gpt-5"]?.limit?.output == 32_000)
  }

  @Test func decodesProviderListAndAuthMethods() throws {
    let providerJSON = """
    {
      "all": [
        {
          "id": "openai",
          "name": "OpenAI",
          "source": "api",
          "env": ["OPENAI_API_KEY"],
          "models": {
            "gpt-5": {
              "id": "gpt-5",
              "providerID": "openai",
              "name": "GPT-5",
              "status": "active",
              "variants": {
                "high": {}
              }
            }
          }
        }
      ],
      "default": {
        "openai": "gpt-5"
      },
      "connected": ["openai"]
    }
    """.data(using: .utf8)!

    let authJSON = """
    {
      "openai": [
        {
          "type": "api",
          "label": "API key",
          "prompts": [
            {
              "type": "text",
              "key": "key",
              "message": "API key"
            }
          ]
        }
      ]
    }
    """.data(using: .utf8)!

    let providers = try JSONDecoder().decode(ProviderListResponse.self, from: providerJSON)
    let auth = try JSONDecoder().decode(ProviderAuthMethodResponse.self, from: authJSON)

    #expect(providers.all.first?.source == "api")
    #expect(providers.all.first?.models["gpt-5"]?.status == "active")
    #expect(providers.connected == ["openai"])
    #expect(auth["openai"]?.first?.prompts?.first?.objectValue?["key"]?.stringValue == "key")
  }

  @Test func decodesProjectAndGlobalEvent() throws {
    let projectJSON = """
    {
      "id": "prj_1",
      "worktree": "/tmp/project",
      "vcs": "git",
      "name": "Project",
      "icon": {
        "override": "hammer"
      },
      "commands": {
        "start": "bun dev"
      },
      "time": {
        "created": 1,
        "updated": 2
      },
      "sandboxes": ["main"]
    }
    """.data(using: .utf8)!

    let eventJSON = """
    {
      "payload": {
        "type": "server.connected",
        "properties": {}
      }
    }
    """.data(using: .utf8)!

    let project = try JSONDecoder().decode(ProjectInfo.self, from: projectJSON)
    let event = try JSONDecoder().decode(GlobalServerEvent.self, from: eventJSON)

    #expect(project.commands?.start == "bun dev")
    #expect(project.icon?.override == "hammer")
    #expect(event.resolvedDirectory == "global")
    #expect(event.payload.eventType == .serverConnected)
  }

  @Test func decodesLSPAndMCPStatusPayloads() throws {
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
    let firstLSP = try #require(lsp.first)

    #expect(firstLSP.status == .connected)
    #expect(mcp["github"]?.status == .connected)
    #expect(mcp["linear"]?.status == .needsAuth)
    #expect(mcp["legacy"]?.status == .unknown("other"))
  }

  @Test func decodesToolPartState() throws {
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

    #expect(part.type == "tool")
    #expect(part.tool == "bash")
    #expect(part.callID == "call_1")
    #expect(part.toolState?.status.rawValue == "completed")
    #expect(part.toolInputString("command") == "ls")
    #expect(part.toolState?.output == "README.md")
  }

  @Test func decodesSessionStatusRetry() throws {
    let json = """
    {
      "type": "retry",
      "attempt": 2,
      "message": "Retrying",
      "next": 174000
    }
    """.data(using: .utf8)!

    let status = try JSONDecoder().decode(SessionStatus.self, from: json)

    #expect(status.type.rawValue == "retry")
    #expect(status.attempt == 2)
    #expect(status.message == "Retrying")
    #expect(status.next == 174_000)
    #expect(status.isRunning == true)
  }

  @Test func serverEventTypeMappingSupportsKnownAndUnknownEvents() {
    let known = ServerEvent(type: "message.part.updated", properties: .object([:]))
    #expect(known.eventType == .messagePartUpdated)

    let heartbeat = ServerEvent(type: "server.heartbeat", properties: .object([:]))
    #expect(heartbeat.eventType == .serverHeartbeat)

    let project = ServerEvent(type: "project.updated", properties: .object([:]))
    #expect(project.eventType == .projectUpdated)

    let lsp = ServerEvent(type: "lsp.updated", properties: .object([:]))
    #expect(lsp.eventType == .lspUpdated)

    let mcp = ServerEvent(type: "mcp.tools.changed", properties: .object([:]))
    #expect(mcp.eventType == .mcpToolsChanged)

    let unknown = ServerEvent(type: "custom.event", properties: .object([:]))
    #expect(unknown.eventType == .unknown("custom.event"))
  }
}
