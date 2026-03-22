import Foundation
import OpenCodeSDK
import Testing

struct OpenCodeClientMessagesTests {
  @Test func messageRoutes() async throws {
    let controller = makeSuccessPathController()
    let client = makeClient(controller: controller)

    let listedMessages = try await client.listMessages(sessionID: "ses_1", limit: 5, before: "cur_0")
    #expect(listedMessages.first?.id == "msg_list")

    let listedMessagesPage = try await client.listMessagesPage(sessionID: "ses_1", limit: 5)
    #expect(listedMessagesPage.nextCursor == "cur_5")
    #expect(listedMessagesPage.nextURL?.absoluteString == "http://localhost:4096/session/ses_1/message?limit=5&before=cur_5")

    let fetchedMessage = try await client.getMessage(sessionID: "ses_1", messageID: "msg_1")
    #expect(fetchedMessage.id == "msg_get")

    let deletedMessage = try await client.deleteMessage(sessionID: "ses_1", messageID: "msg_1")
    #expect(deletedMessage == true)

    let sent = try await client.sendMessage(sessionID: "ses_1", body: PromptRequest(parts: [.text("Hello")]))
    #expect(sent.id == "msg_send")

    try await client.sendMessageAsync(sessionID: "ses_1", body: PromptRequest(parts: [.text("async")]))

    let commandMessage = try await client.sendSessionCommand(
      sessionID: "ses_1",
      body: SessionCommandRequest(
        messageID: "msg_cmd_1",
        agent: "build",
        model: "openai/gpt-5",
        arguments: "--all",
        command: "fix",
        variant: "high",
        parts: [FilePartInput(id: "part_file_1", mime: "image/png", filename: "image.png", url: "data:image/png;base64,abc")]
      )
    )
    #expect(commandMessage.id == "msg_command")

    let shellMessage = try await client.sendSessionShell(
      sessionID: "ses_1",
      body: SessionShellRequest(agent: "build", model: ModelSelector(providerID: "openai", modelID: "gpt-5"), command: "git status")
    )
    #expect(shellMessage.id == "msg_shell")

    let updatedPart = try await client.updatePart(
      sessionID: "ses_1",
      messageID: "msg_1",
      partID: "part_patch_1",
      part: MessagePart(
        id: "part_patch_1",
        sessionID: "ses_1",
        messageID: "msg_1",
        type: "text",
        text: "Updated text",
        tool: nil,
        raw: .object([
          "id": .string("part_patch_1"),
          "sessionID": .string("ses_1"),
          "messageID": .string("msg_1"),
          "type": .string("text"),
          "text": .string("Updated text"),
        ])
      )
    )
    #expect(updatedPart.text == "Updated text")

    let deletedPart = try await client.deletePart(sessionID: "ses_1", messageID: "msg_1", partID: "part_patch_1")
    #expect(deletedPart == true)

    let requests = controller.recordedRequests
    #expect(requests.contains { $0.url?.absoluteString.contains("limit=5") == true })
    #expect(requests.contains { $0.url?.absoluteString.contains("before=cur_0") == true })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/message/msg_1" && $0.httpMethod == "DELETE" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/command" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/shell" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/message/msg_1/part/part_patch_1" && $0.httpMethod == "PATCH" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/message/msg_1/part/part_patch_1" && $0.httpMethod == "DELETE" })
  }
}
