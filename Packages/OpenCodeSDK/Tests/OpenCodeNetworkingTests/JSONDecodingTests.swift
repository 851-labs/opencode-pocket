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

  @Test func decodesProjectWithInitializedTimestamp() throws {
    let json = """
    {
      "id": "prj_git",
      "worktree": "/tmp/project",
      "vcs": "git",
      "name": "Git Ready",
      "icon": null,
      "commands": null,
      "time": {
        "created": 1,
        "updated": 4,
        "initialized": 4
      },
      "sandboxes": []
    }
    """.data(using: .utf8)!

    let project = try JSONDecoder().decode(ProjectInfo.self, from: json)

    #expect(project.vcs == "git")
    #expect(project.time.initialized == 4)
  }

  @Test func decodesFileContentStatusAndVCSInfo() throws {
    let fileContentJSON = """
    {
      "type": "text",
      "content": "print(\\\"Hello\\\")",
      "diff": "@@ -1 +1 @@",
      "patch": {
        "oldFileName": "a.swift",
        "newFileName": "a.swift",
        "hunks": [
          {
            "oldStart": 1,
            "oldLines": 1,
            "newStart": 1,
            "newLines": 1,
            "lines": ["-old", "+new"]
          }
        ]
      },
      "mimeType": "text/x-swift"
    }
    """.data(using: .utf8)!

    let fileStatusJSON = """
    [
      {
        "path": "README.md",
        "added": 3,
        "removed": 1,
        "status": "modified"
      }
    ]
    """.data(using: .utf8)!

    let vcsJSON = """
    {
      "branch": "main"
    }
    """.data(using: .utf8)!

    let fileContent = try JSONDecoder().decode(FileContent.self, from: fileContentJSON)
    let fileStatus = try JSONDecoder().decode([FileStatusEntry].self, from: fileStatusJSON)
    let vcs = try JSONDecoder().decode(VCSInfo.self, from: vcsJSON)

    #expect(fileContent.type == .text)
    #expect(fileContent.patch?.hunks.first?.lines == ["-old", "+new"])
    #expect(fileStatus.first?.status == .modified)
    #expect(vcs.branch == "main")
  }

  @Test func decodesCommandCatalog() throws {
    let json = """
    [
      {
        "name": "fix",
        "description": "Fix issues",
        "agent": "build",
        "model": "openai/gpt-5",
        "source": "command",
        "template": "Fix {{input}}",
        "subtask": true,
        "hints": ["be precise"]
      },
      {
        "name": "custom",
        "template": "Run {{input}}",
        "source": "other",
        "hints": []
      }
    ]
    """.data(using: .utf8)!

    let commands = try JSONDecoder().decode([CommandDescriptor].self, from: json)

    #expect(commands.first?.source == .command)
    #expect(commands.first?.hints == ["be precise"])
    #expect(commands.last?.source == .unknown("other"))
  }

  @Test func decodesTextMatchesAndWorkspaceSymbols() throws {
    let matchesJSON = """
    [
      {
        "path": {
          "text": "Sources/App.swift"
        },
        "lines": {
          "text": "let value = 1"
        },
        "line_number": 42,
        "absolute_offset": 1024,
        "submatches": [
          {
            "match": {
              "text": "value"
            },
            "start": 4,
            "end": 9
          }
        ]
      }
    ]
    """.data(using: .utf8)!

    let symbolsJSON = """
    [
      {
        "name": "renderWorkspace",
        "kind": 12,
        "location": {
          "uri": "file:///tmp/project/Sources/App.swift",
          "range": {
            "start": {
              "line": 9,
              "character": 2
            },
            "end": {
              "line": 14,
              "character": 1
            }
          }
        }
      }
    ]
    """.data(using: .utf8)!

    let matches = try JSONDecoder().decode([TextSearchMatch].self, from: matchesJSON)
    let symbols = try JSONDecoder().decode([WorkspaceSymbol].self, from: symbolsJSON)

    #expect(matches.first?.path.text == "Sources/App.swift")
    #expect(matches.first?.submatches.first?.start == 4)
    #expect(symbols.first?.location.range.end.character == 1)
    #expect(symbols.first?.id.contains("renderWorkspace") == true)
  }

  @Test func decodesAuthCredentialAndOAuthAuthorization() throws {
    let authJSON = """
    {
      "type": "oauth",
      "refresh": "refresh-token",
      "access": "access-token",
      "expires": 42,
      "accountId": "acct_1"
    }
    """.data(using: .utf8)!

    let authorizationJSON = """
    {
      "url": "https://provider.example/auth",
      "method": "code",
      "instructions": "Paste the code here"
    }
    """.data(using: .utf8)!

    let auth = try JSONDecoder().decode(AuthCredential.self, from: authJSON)
    let authorization = try JSONDecoder().decode(ProviderOAuthAuthorization.self, from: authorizationJSON)

    switch auth {
    case let .oauth(refresh, access, expires, accountID, _):
      #expect(refresh == "refresh-token")
      #expect(access == "access-token")
      #expect(expires == 42)
      #expect(accountID == "acct_1")
    default:
      Issue.record("Expected oauth auth credential")
    }

    #expect(authorization.method == "code")
    #expect(authorization.url == "https://provider.example/auth")
  }

  @Test func encodesMCPConfigurationsAndDecodesAuthResponses() throws {
    let local = MCPConfiguration.local(
      MCPLocalConfiguration(
        command: ["bun", "run", "server"],
        environment: ["TOKEN": "abc"],
        enabled: true,
        timeout: 5000
      )
    )
    let remote = MCPConfiguration.remote(
      MCPRemoteConfiguration(
        url: "https://mcp.example",
        headers: ["Authorization": "Bearer token"],
        oauth: .config(MCPOAuthConfiguration(clientID: "client", scope: "repo")),
        timeout: 3000
      )
    )
    let startJSON = """
    {
      "authorizationUrl": "https://mcp.example/auth"
    }
    """.data(using: .utf8)!
    let removeJSON = """
    {
      "success": true
    }
    """.data(using: .utf8)!

    let localData = try JSONEncoder().encode(local)
    let remoteData = try JSONEncoder().encode(remote)
    let localObject = try #require(JSONSerialization.jsonObject(with: localData) as? [String: Any])
    let remoteObject = try #require(JSONSerialization.jsonObject(with: remoteData) as? [String: Any])
    let start = try JSONDecoder().decode(MCPOAuthStartResponse.self, from: startJSON)
    let remove = try JSONDecoder().decode(MCPOAuthRemoveResponse.self, from: removeJSON)

    #expect(localObject["type"] as? String == "local")
    #expect((localObject["command"] as? [String]) == ["bun", "run", "server"])
    #expect(remoteObject["type"] as? String == "remote")
    #expect(remoteObject["url"] as? String == "https://mcp.example")
    #expect(start.authorizationURL == "https://mcp.example/auth")
    #expect(remove.success == true)
  }

  @Test func decodesSkillAndFormatterStatus() throws {
    let skillsJSON = """
    [
      {
        "name": "swift-concurrency-pro",
        "description": "Reviews Swift concurrency code",
        "location": "/tmp/skills/swift/SKILL.md",
        "content": "# Skill\\nUse async await."
      }
    ]
    """.data(using: .utf8)!
    let formatterJSON = """
    [
      {
        "name": "swiftformat",
        "extensions": ["swift"],
        "enabled": true
      }
    ]
    """.data(using: .utf8)!

    let skills = try JSONDecoder().decode([SkillInfo].self, from: skillsJSON)
    let formatter = try JSONDecoder().decode([FormatterStatus].self, from: formatterJSON)

    #expect(skills.first?.location == "/tmp/skills/swift/SKILL.md")
    #expect(skills.first?.content.contains("async await") == true)
    #expect(formatter.first?.extensions == ["swift"])
    #expect(formatter.first?.enabled == true)
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
