import OpenCodeModels
import XCTest

final class MessageEventNormalizationTests: XCTestCase {
  func testPartDeltaMutationAppendsTextToExistingPart() {
    let sessionID = "ses_1"
    let messagesBySession = [sessionID: [makeEnvelope(sessionID: sessionID, messageID: "msg_1", partID: "prt_1", text: "hello")]]
    let properties: [String: JSONValue] = [
      "sessionID": .string(sessionID),
      "messageID": .string("msg_1"),
      "partID": .string("prt_1"),
      "field": .string("text"),
      "delta": .string(" world"),
    ]

    let mutation = MessageEnvelope.partDeltaMutation(from: properties, messagesBySession: messagesBySession)
    XCTAssertEqual(mutation?.sessionID, sessionID)
    XCTAssertEqual(mutation?.messages.first?.parts.first?.text, "hello world")
  }

  func testPartUpdatedMutationInsertsPartByStableOrder() {
    let sessionID = "ses_1"
    let messagesBySession = [sessionID: [makeEnvelope(sessionID: sessionID, messageID: "msg_1", partID: "prt_2", text: "two")]]

    let incomingPart = makePart(sessionID: sessionID, messageID: "msg_1", partID: "prt_1", text: "one")
    let properties: [String: JSONValue] = [
      "part": incomingPart.raw,
    ]

    let mutation = MessageEnvelope.partUpdatedMutation(from: properties, messagesBySession: messagesBySession)
    XCTAssertEqual(mutation?.messages.first?.parts.map(\.id), ["prt_1", "prt_2"])
  }

  func testMessageUpdatedMutationCreatesMissingMessageWithNoParts() {
    let sessionID = "ses_1"
    let messagesBySession: [String: [MessageEnvelope]] = [sessionID: []]
    let info = makeInfo(sessionID: sessionID, messageID: "msg_9", role: .assistant)
    let properties: [String: JSONValue] = [
      "info": info.raw,
    ]

    let mutation = MessageEnvelope.messageUpdatedMutation(from: properties, messagesBySession: messagesBySession)
    XCTAssertEqual(mutation?.messages.count, 1)
    XCTAssertEqual(mutation?.messages.first?.info.id, "msg_9")
    XCTAssertEqual(mutation?.messages.first?.parts.count, 0)
  }

  func testMessageRemovalMutationRemovesMessageByID() {
    let sessionID = "ses_1"
    let messagesBySession = [
      sessionID: [
        makeEnvelope(sessionID: sessionID, messageID: "msg_1", partID: "prt_1", text: "a"),
        makeEnvelope(sessionID: sessionID, messageID: "msg_2", partID: "prt_2", text: "b"),
      ],
    ]
    let properties: [String: JSONValue] = [
      "sessionID": .string(sessionID),
      "messageID": .string("msg_1"),
    ]

    let mutation = MessageEnvelope.messageRemovalMutation(from: properties, messagesBySession: messagesBySession)
    XCTAssertEqual(mutation?.messages.map(\.info.id), ["msg_2"])
  }

  func testPartRemovalMutationRemovesSinglePart() {
    let sessionID = "ses_1"
    let messagesBySession = [
      sessionID: [
        MessageEnvelope(
          info: makeInfo(sessionID: sessionID, messageID: "msg_1", role: .assistant),
          parts: [
            makePart(sessionID: sessionID, messageID: "msg_1", partID: "prt_1", text: "one"),
            makePart(sessionID: sessionID, messageID: "msg_1", partID: "prt_2", text: "two"),
          ]
        ),
      ],
    ]
    let properties: [String: JSONValue] = [
      "sessionID": .string(sessionID),
      "messageID": .string("msg_1"),
      "partID": .string("prt_2"),
    ]

    let mutation = MessageEnvelope.partRemovalMutation(from: properties, messagesBySession: messagesBySession)
    XCTAssertEqual(mutation?.messages.first?.parts.map(\.id), ["prt_1"])
  }

  private func makeEnvelope(sessionID: String, messageID: String, partID: String, text: String) -> MessageEnvelope {
    MessageEnvelope(
      info: makeInfo(sessionID: sessionID, messageID: messageID, role: .assistant),
      parts: [makePart(sessionID: sessionID, messageID: messageID, partID: partID, text: text)]
    )
  }

  private func makeInfo(sessionID: String, messageID: String, role: MessageRole) -> MessageMetadata {
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

  private func makePart(sessionID: String, messageID: String, partID: String, text: String) -> MessagePart {
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
}
