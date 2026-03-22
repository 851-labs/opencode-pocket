import Foundation
import OpenCodeSDK
import Testing

struct RemainingModelCoverageTests {
  @Test func permissionAndQuestionModelsCoverInitializersAndIDs() {
    let toolRef = ToolCallReference(messageID: "msg_1", callID: "call_1")
    let permission = PermissionRequest(
      id: "perm_1",
      sessionID: "ses_1",
      permission: "edit",
      patterns: ["src/**"],
      metadata: ["tool": .string("edit")],
      always: ["src/**"],
      tool: toolRef
    )
    #expect(permission.id == "perm_1")
    #expect(permission.tool?.callID == "call_1")

    let option = QuestionOption(label: "Yes", description: "Confirm")
    let definition = QuestionDefinition(question: "Proceed?", header: "Approval", options: [option], multiple: false, custom: true)
    let question = QuestionRequest(id: "question_1", sessionID: "ses_1", questions: [definition], tool: toolRef)
    #expect(question.id == "question_1")
    #expect(question.questions.first?.options.first?.label == "Yes")

    let todo = TodoItem(content: "Ship it", status: "done", priority: "high")
    #expect(todo.id == "Ship it::done::high")

    let reply = PermissionReplyRequest(reply: .always, message: "ok")
    let questionReply = QuestionReplyRequest(answers: [["Yes"]])
    #expect(reply.reply == .always)
    #expect(questionReply.answers == [["Yes"]])
  }

  @Test func settingsAndSessionFallbacksAreCovered() throws {
    let authorization = ProviderOAuthAuthorization(url: "https://provider.example/auth", method: "code", instructions: "Paste code")
    #expect(authorization.method == "code")

    let session = Session(
      id: "ses_zero",
      slug: "zero",
      projectID: "prj_1",
      directory: "/tmp/project",
      parentID: nil,
      title: "Zero",
      version: "1",
      time: SessionTimestamps(created: nil, updated: nil)
    )
    #expect(session.sortTimestamp == 0)

    let assistantEnvelope = MessageEnvelope(
      info: MessageMetadata(id: "msg_1", sessionID: "ses_1", role: .assistant, agent: nil, providerID: nil, modelID: nil, parentID: nil, raw: .object(["id": .string("msg_1"), "sessionID": .string("ses_1"), "role": .string("assistant")])),
      parts: []
    )
    let userEnvelope = MessageEnvelope(
      info: MessageMetadata(id: "msg_2", sessionID: "ses_1", role: .user, agent: nil, providerID: nil, modelID: nil, parentID: nil, raw: .object(["id": .string("msg_2"), "sessionID": .string("ses_1"), "role": .string("user")])),
      parts: []
    )
    #expect(assistantEnvelope.textBody == "(Assistant response has no text parts yet)")
    #expect(userEnvelope.textBody == "(No text content)")

    let encodedMetadata = try JSONEncoder().encode(assistantEnvelope.info)
    let encodedObject = try #require(JSONSerialization.jsonObject(with: encodedMetadata) as? [String: Any])
    #expect(encodedObject["id"] as? String == "msg_1")
    #expect(MessageRole.user.rawValue == "user")
  }

  @Test func messageMutationBranchesCoverFallbackPaths() {
    let sessionID = "ses_1"
    let envelope = makeCoverageEnvelope(sessionID: sessionID, messageID: "msg_1", partID: "prt_2", text: "two")

    let replacementPart = makeCoveragePart(sessionID: sessionID, messageID: "msg_1", partID: "prt_2", text: "replacement")
    let updated = MessageEnvelope.partUpdatedMutation(from: ["part": replacementPart.raw], messagesBySession: [sessionID: [envelope]])
    #expect(updated?.messages.first?.parts.first?.text == "replacement")

    let directInfo = makeCoverageInfo(sessionID: sessionID, messageID: "msg_1", role: .assistant)
    let updatedMessage = MessageEnvelope.messageUpdatedMutation(from: directInfo.raw.objectValue ?? [:], messagesBySession: [sessionID: [envelope]])
    #expect(updatedMessage?.messages.first?.info.id == "msg_1")

    let noRemoval = MessageEnvelope.messageRemovalMutation(from: ["sessionID": .string(sessionID), "messageID": .string("missing")], messagesBySession: [sessionID: [envelope]])
    #expect(noRemoval == nil)

    let noPartRemoval = MessageEnvelope.partRemovalMutation(from: ["sessionID": .string(sessionID), "messageID": .string("msg_1"), "partID": .string("missing")], messagesBySession: [sessionID: [envelope]])
    #expect(noPartRemoval == nil)
  }

  @Test func messagePartAndJsonHelpersCoverRemainingBranches() throws {
    let notContextTool = MessagePart(
      id: "part_1",
      sessionID: "ses_1",
      messageID: "msg_1",
      type: "tool",
      text: nil,
      tool: "write",
      raw: .object([
        "id": .string("part_1"),
        "sessionID": .string("ses_1"),
        "messageID": .string("msg_1"),
        "type": .string("tool"),
        "tool": .string("write"),
        "model": .object(["providerID": .string("openai"), "modelID": .string("gpt-5")]),
      ])
    )
    #expect(notContextTool.isContextTool == false)
    #expect(notContextTool.toolInputStringArray("missing") == [])

    let renderVariants: [MessagePart] = [
      makeCoverageMessagePart(type: "tool"),
      makeCoverageMessagePart(type: "step-finish"),
      makeCoverageMessagePart(type: "retry"),
      makeCoverageMessagePart(type: "patch"),
      makeCoverageMessagePart(type: "agent"),
      makeCoverageMessagePart(type: "subtask"),
      makeCoverageMessagePart(type: "file"),
    ]
    #expect(renderVariants[0].renderedText == "[Tool]")
    #expect(renderVariants[1].renderedText == "[Step finished]")
    #expect(renderVariants[2].renderedText == "[Retrying request]")
    #expect(renderVariants[3].renderedText == "[Patch applied]")
    #expect(renderVariants[4].renderedText == "[Agent selected]")
    #expect(renderVariants[5].renderedText == "[Subtask created]")
    #expect(renderVariants[6].renderedText == "[File attached]")

    let subtaskJSON = #"{"id":"part_subtask","sessionID":"ses_1","messageID":"msg_1","type":"subtask","model":{"providerID":"openai","modelID":"gpt-5"}}"#.data(using: .utf8)!
    let subtaskPart = try JSONDecoder().decode(MessagePart.self, from: subtaskJSON)
    #expect(subtaskPart.subtaskModel == ModelSelector(providerID: "openai", modelID: "gpt-5"))

    let nonToolPart = MessagePart(
      id: "part_text",
      sessionID: "ses_1",
      messageID: "msg_1",
      type: "text",
      text: "Hello",
      tool: nil,
      raw: .object([
        "id": .string("part_text"),
        "sessionID": .string("ses_1"),
        "messageID": .string("msg_1"),
        "type": .string("text"),
        "text": .string("Hello"),
      ])
    )
    #expect(nonToolPart.isContextTool == false)

    let invalidRawPart = MessagePart(
      id: "part_invalid",
      sessionID: "ses_1",
      messageID: "msg_1",
      type: "text",
      text: nil,
      tool: nil,
      raw: .string("invalid")
    )
    #expect(invalidRawPart.appendingDelta(field: "text", delta: "x") == nil)

    let boolData = try JSONEncoder().encode(JSONValue.bool(true))
    let nullData = try JSONEncoder().encode(JSONValue.null)
    let boolValue = try JSONDecoder().decode(JSONValue.self, from: boolData)
    let nullValue = try JSONDecoder().decode(JSONValue.self, from: nullData)
    #expect(boolValue.boolValue == true)
    #expect(nullValue.compactDescription == "null")

    let dictionary: [String: JSONValue] = ["flag": .bool(true)]
    #expect(dictionary.bool(for: "flag") == true)
  }

  @Test func tokenUsageAndToolExecutionStatusCoverRemainingBranches() throws {
    let cacheJSON = #"{"read":2,"write":3}"#.data(using: .utf8)!
    let cache = try JSONDecoder().decode(MessageTokenUsage.CacheUsage.self, from: cacheJSON)
    #expect(cache.read == 2)
    #expect(cache.write == 3)

    let usage = MessageTokenUsage(input: 1, output: 2, reasoning: 3, cache: cache)
    let usageData = try JSONEncoder().encode(usage)
    let usageObject = try #require(JSONSerialization.jsonObject(with: usageData) as? [String: Any])
    #expect(usageObject["total"] == nil)
    #expect(usageObject["input"] as? Int == 1)

    let pending = ToolExecutionStatus.pending
    let error = ToolExecutionStatus.error
    #expect(pending.rawValue == "pending")
    #expect(error.rawValue == "error")

    let pendingData = try JSONEncoder().encode(ToolExecutionStatus.pending)
    let runningData = try JSONEncoder().encode(ToolExecutionStatus.running)
    let completedData = try JSONEncoder().encode(ToolExecutionStatus.completed)
    let errorData = try JSONEncoder().encode(ToolExecutionStatus.error)
    #expect(try JSONDecoder().decode(ToolExecutionStatus.self, from: pendingData) == .pending)
    #expect(try JSONDecoder().decode(ToolExecutionStatus.self, from: runningData) == .running)
    #expect(try JSONDecoder().decode(ToolExecutionStatus.self, from: completedData) == .completed)
    #expect(try JSONDecoder().decode(ToolExecutionStatus.self, from: errorData) == .error)
  }
}

private func makeCoverageEnvelope(sessionID: String, messageID: String, partID: String, text: String) -> MessageEnvelope {
  MessageEnvelope(
    info: makeCoverageInfo(sessionID: sessionID, messageID: messageID, role: .assistant),
    parts: [makeCoveragePart(sessionID: sessionID, messageID: messageID, partID: partID, text: text)]
  )
}

private func makeCoverageInfo(sessionID: String, messageID: String, role: MessageRole) -> MessageMetadata {
  MessageMetadata(
    id: messageID,
    sessionID: sessionID,
    role: role,
    agent: "build",
    providerID: nil,
    modelID: nil,
    parentID: nil,
    raw: .object([
      "id": .string(messageID),
      "sessionID": .string(sessionID),
      "role": .string(role.rawValue),
      "agent": .string("build"),
    ])
  )
}

private func makeCoveragePart(sessionID: String, messageID: String, partID: String, text: String) -> MessagePart {
  MessagePart(
    id: partID,
    sessionID: sessionID,
    messageID: messageID,
    type: "text",
    text: text,
    tool: nil,
    raw: .object([
      "id": .string(partID),
      "sessionID": .string(sessionID),
      "messageID": .string(messageID),
      "type": .string("text"),
      "text": .string(text),
    ])
  )
}

private func makeCoverageMessagePart(
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
    tool: type == "tool" ? nil : nil,
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
