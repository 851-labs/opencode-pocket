import Foundation
import OpenCodeSDK
import Testing

struct ModelLogicCoverageTests {
  @Test func serverEventTypesRoundTripAcrossKnownAndUnknownCases() {
    let mappings: [(String, ServerEventType)] = [
      ("server.connected", .serverConnected),
      ("server.heartbeat", .serverHeartbeat),
      ("global.disposed", .globalDisposed),
      ("project.updated", .projectUpdated),
      ("file.watcher.updated", .fileWatcherUpdated),
      ("server.instance.disposed", .serverInstanceDisposed),
      ("vcs.branch.updated", .vcsBranchUpdated),
      ("session.created", .sessionCreated),
      ("session.updated", .sessionUpdated),
      ("session.deleted", .sessionDeleted),
      ("session.idle", .sessionIdle),
      ("session.status", .sessionStatus),
      ("session.error", .sessionError),
      ("session.diff", .sessionDiff),
      ("todo.updated", .todoUpdated),
      ("permission.asked", .permissionAsked),
      ("permission.replied", .permissionReplied),
      ("question.asked", .questionAsked),
      ("question.replied", .questionReplied),
      ("question.rejected", .questionRejected),
      ("message.part.delta", .messagePartDelta),
      ("message.part.updated", .messagePartUpdated),
      ("message.part.removed", .messagePartRemoved),
      ("message.updated", .messageUpdated),
      ("message.removed", .messageRemoved),
      ("lsp.updated", .lspUpdated),
      ("mcp.tools.changed", .mcpToolsChanged),
    ]

    for (raw, expected) in mappings {
      let eventType = ServerEventType(rawValue: raw)
      #expect(eventType == expected)
      #expect(eventType.rawValue == raw)
    }

    let unknown = ServerEventType(rawValue: "mystery.event")
    #expect(unknown == .unknown("mystery.event"))
    #expect(unknown.rawValue == "mystery.event")
  }

  @Test func serverEventHelpersDecodePropertiesAndGlobalFallback() {
    let event = ServerEvent(
      type: "session.status",
      properties: .object([
        "type": .string("busy"),
      ])
    )
    let decoded = event.decodeProperties(as: SessionStatus.self)
    #expect(decoded?.type == .busy)
    #expect(event.eventType == .sessionStatus)

    let global = GlobalServerEvent(directory: nil, payload: event)
    #expect(global.resolvedDirectory == "global")
  }

  @Test func messagePartHelpersCoverRenderingAndToolInputs() throws {
    let toolState = ToolExecutionState(
      status: .running,
      input: [
        "path": .string("README.md"),
        "count": .number(2),
        "items": .array([.string("a"), .string("b")]),
      ],
      output: "done",
      title: "Read",
      error: nil,
      metadata: ["source": .string("sdk")],
      time: ToolExecutionTime(start: 1, end: 2, compacted: 3)
    )

    let toolPart = MessagePart(
      id: "part_tool",
      sessionID: "ses_1",
      messageID: "msg_1",
      type: "tool",
      text: nil,
      tool: "read",
      callID: "call_1",
      toolState: toolState,
      metadata: ["kind": .string("context")],
      files: [],
      raw: .object([
        "id": .string("part_tool"),
        "sessionID": .string("ses_1"),
        "messageID": .string("msg_1"),
        "type": .string("tool"),
        "tool": .string("read"),
        "state": toolState.raw,
      ])
    )

    #expect(toolPart.isContextTool == true)
    #expect(toolPart.isToolRunning == true)
    #expect(toolPart.toolInputString("path") == "README.md")
    #expect(toolPart.toolInputNumber("count") == 2)
    #expect(toolPart.toolInputStringArray("items") == ["a", "b"])
    #expect(toolPart.renderedText == "[Tool: read]")

    let variants: [(MessagePart, String?)] = [
      (makeMessagePart(type: "text", text: "hello"), "hello"),
      (makeMessagePart(type: "reasoning", text: "thinking"), "thinking"),
      (makeMessagePart(type: "step-start"), "[Step started]"),
      (makeMessagePart(type: "step-finish", reason: "done"), "[Step finished: done]"),
      (makeMessagePart(type: "retry", attempt: 3), "[Retrying request #3]"),
      (makeMessagePart(type: "compaction"), "[Context compacted]"),
      (makeMessagePart(type: "patch", files: ["a.swift", "b.swift"]), "[Patch for 2 file(s)]"),
      (makeMessagePart(type: "agent", agentName: "builder"), "[Agent: builder]"),
      (makeMessagePart(type: "subtask", subtaskDescription: "Write tests"), "[Subtask: Write tests]"),
      (makeMessagePart(type: "file", fileName: "image.png"), "[File: image.png]"),
      (makeMessagePart(type: "unknown"), nil),
    ]

    for (part, expected) in variants {
      #expect(part.renderedText == expected)
    }

    let deltaPart = MessagePart(
      id: "part_delta",
      sessionID: "ses_1",
      messageID: "msg_1",
      type: "text",
      text: "hello",
      tool: nil,
      raw: .object([
        "id": .string("part_delta"),
        "sessionID": .string("ses_1"),
        "messageID": .string("msg_1"),
        "type": .string("text"),
        "text": .string("hello"),
        "metadata": .object(["nested": .object(["value": .string("a")])]),
      ])
    )
    let appended = try #require(deltaPart.appendingDelta(field: "metadata.nested.value", delta: "b"))
    #expect(appended.metadata?["nested"]?.objectValue?["value"]?.stringValue == "ab")
    #expect(deltaPart.appendingDelta(field: "", delta: "x") == nil)

    do {
      _ = try JSONDecoder().decode(MessagePart.self, from: Data(#"[]"#.utf8))
      Issue.record("Expected invalid MessagePart decode to throw")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains("Message part is not an object") == true)
    }

    do {
      _ = try JSONDecoder().decode(MessagePart.self, from: Data(#"{"id":"part"}"#.utf8))
      Issue.record("Expected missing MessagePart fields to throw")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains("Message part missing required fields") == true)
    }
  }

  @Test func messageMetadataCoversFallbacksAndInvalidShapes() throws {
    let json = #"{"id":"msg_1","sessionID":"ses_1","role":"mystery","time":{"created":1,"completed":2},"model":{"providerID":"openai","modelID":"gpt-5"},"error":{"message":"boom"},"summary":{"diffs":[{"file":"a.swift","before":"old","after":"new","additions":1,"deletions":0,"status":"modified"}]},"tokens":{"input":1,"output":2}}"#.data(using: .utf8)!
    let metadata = try JSONDecoder().decode(MessageMetadata.self, from: json)

    #expect(metadata.role == .unknown)
    #expect(metadata.providerID == "openai")
    #expect(metadata.modelID == "gpt-5")
    #expect(metadata.errorDisplayText == "boom")
    #expect(metadata.summaryDiffs.count == 1)

    let direct = MessageMetadata(
      id: "msg_2",
      sessionID: "ses_1",
      role: .assistant,
      agent: "build",
      providerID: "anthropic",
      modelID: "claude",
      mode: "edit",
      variant: "fast",
      parentID: "msg_1",
      createdAt: 1,
      completedAt: 2,
      error: MessageFailure(name: "Oops", message: "failed"),
      cost: 0.2,
      tokenUsage: MessageTokenUsage(input: 1, output: 2),
      summaryDiffs: [],
      raw: .object(["id": .string("msg_2"), "sessionID": .string("ses_1"), "role": .string("assistant")])
    )
    #expect(direct.errorDisplayText == "failed")

    let encodedDirect = try JSONEncoder().encode(direct)
    let encodedObject = try #require(JSONSerialization.jsonObject(with: encodedDirect) as? [String: Any])
    #expect(encodedObject["id"] as? String == "msg_2")

    do {
      _ = try JSONDecoder().decode(MessageMetadata.self, from: Data(#"[]"#.utf8))
      Issue.record("Expected invalid MessageMetadata decode to throw")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains("Message info is not an object") == true)
    }

    do {
      _ = try JSONDecoder().decode(MessageMetadata.self, from: Data(#"{"role":"assistant"}"#.utf8))
      Issue.record("Expected missing MessageMetadata fields to throw")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains("Message info missing id or sessionID") == true)
    }
  }

  @Test func promptModelsEncodeAllPartKinds() throws {
    let request = PromptRequest(
      messageID: "msg_1",
      model: ModelSelector(providerID: "openai", modelID: "gpt-5"),
      agent: "build",
      noReply: true,
      system: "You are helpful",
      variant: "fast",
      parts: [
        .text("hello"),
        .file(FilePartInput(id: "file_1", mime: "image/png", filename: "image.png", url: "data:image/png;base64,abc", source: .object(["kind": .string("clipboard")]))),
        .agent(AgentPartInput(name: "builder")),
        .subtask(SubtaskPartInput(prompt: "write tests", description: "Coverage", agent: "build", model: ModelSelector(providerID: "openai", modelID: "gpt-5"), command: "/fix")),
      ]
    )

    let data = try JSONEncoder().encode(request)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    let parts = try #require(object["parts"] as? [[String: Any]])

    #expect(object["messageID"] as? String == "msg_1")
    #expect(parts.count == 4)
    #expect(parts[0]["type"] as? String == "text")
    #expect(parts[1]["type"] as? String == "file")
    #expect(parts[2]["type"] as? String == "agent")
    #expect(parts[3]["type"] as? String == "subtask")
  }

  @Test func toolExecutionModelsCoverStateAndInvalidDecode() throws {
    #expect(ToolExecutionStatus(rawValue: "pending").isInFlight == true)
    #expect(ToolExecutionStatus(rawValue: "running").isInFlight == true)
    #expect(ToolExecutionStatus(rawValue: "completed").isInFlight == false)
    #expect(ToolExecutionStatus(rawValue: "weird") == .unknown("weird"))

    let encodedStatus = try JSONEncoder().encode(ToolExecutionStatus.unknown("weird"))
    let decodedStatus = try JSONDecoder().decode(ToolExecutionStatus.self, from: encodedStatus)
    #expect(decodedStatus == .unknown("weird"))

    let state = ToolExecutionState(
      status: .completed,
      input: ["path": .string("README.md")],
      output: "done",
      title: "Read File",
      error: "warn",
      metadata: ["key": .string("value")],
      time: ToolExecutionTime(start: 1, end: 2, compacted: 3)
    )
    let stateData = try JSONEncoder().encode(state)
    let stateJSON = try #require(JSONSerialization.jsonObject(with: stateData) as? [String: Any])
    #expect(stateJSON["status"] as? String == "completed")
    #expect((stateJSON["time"] as? [String: Any])?["compacted"] as? Double == 3)

    let decodedState = try JSONDecoder().decode(ToolExecutionState.self, from: stateData)
    #expect(decodedState.status == .completed)
    #expect(decodedState.input["path"]?.stringValue == "README.md")
    #expect(decodedState.metadata?["key"]?.stringValue == "value")

    let sparseJSON = #"{"status":"pending"}"#.data(using: .utf8)!
    let sparse = try JSONDecoder().decode(ToolExecutionState.self, from: sparseJSON)
    #expect(sparse.input == [:])
    #expect(sparse.time == nil)

    do {
      _ = try JSONDecoder().decode(ToolExecutionState.self, from: Data(#"[]"#.utf8))
      Issue.record("Expected invalid ToolExecutionState decode to throw")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains("Tool state is not an object") == true)
    }
  }
}

private func makeMessagePart(
  type: String,
  text: String? = nil,
  files: [String] = [],
  reason: String? = nil,
  attempt: Int? = nil,
  agentName: String? = nil,
  subtaskDescription: String? = nil,
  fileName: String? = nil
) -> MessagePart {
  MessagePart(
    id: "part_1",
    sessionID: "ses_1",
    messageID: "msg_1",
    type: type,
    text: text,
    tool: type == "tool" ? "read" : nil,
    files: files,
    reason: reason,
    attempt: attempt,
    agentName: agentName,
    subtaskDescription: subtaskDescription,
    fileName: fileName,
    raw: .object([
      "id": .string("part_1"),
      "sessionID": .string("ses_1"),
      "messageID": .string("msg_1"),
      "type": .string(type),
      "text": text.map(JSONValue.string) ?? .null,
      "files": .array(files.map(JSONValue.string)),
    ])
  )
}
