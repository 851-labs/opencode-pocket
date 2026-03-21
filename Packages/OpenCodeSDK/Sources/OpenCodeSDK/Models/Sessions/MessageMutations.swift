import Foundation

public extension MessageEnvelope {
  static func partDeltaMutation(
    from properties: [String: JSONValue],
    messagesBySession: [String: [MessageEnvelope]]
  ) -> (sessionID: String, messages: [MessageEnvelope])? {
    guard
      let sessionID = properties.string(for: "sessionID"),
      let messageID = properties.string(for: "messageID"),
      let partID = properties.string(for: "partID"),
      let field = properties.string(for: "field"),
      let delta = properties.string(for: "delta"),
      !delta.isEmpty,
      var messages = messagesBySession[sessionID],
      let messageIndex = messages.firstIndex(where: { $0.info.id == messageID }),
      let partIndex = messages[messageIndex].parts.firstIndex(where: { $0.id == partID }),
      let updatedPart = messages[messageIndex].parts[partIndex].appendingDelta(field: field, delta: delta)
    else {
      return nil
    }

    var updatedParts = messages[messageIndex].parts
    updatedParts[partIndex] = updatedPart
    messages[messageIndex] = MessageEnvelope(info: messages[messageIndex].info, parts: updatedParts)
    return (sessionID: sessionID, messages: messages)
  }

  static func partUpdatedMutation(
    from properties: [String: JSONValue],
    messagesBySession: [String: [MessageEnvelope]]
  ) -> (sessionID: String, messages: [MessageEnvelope])? {
    guard
      let partValue = properties["part"],
      let part = partValue.decoded(as: MessagePart.self),
      var messages = messagesBySession[part.sessionID],
      let messageIndex = messages.firstIndex(where: { $0.info.id == part.messageID })
    else {
      return nil
    }

    var updatedParts = messages[messageIndex].parts
    if let partIndex = updatedParts.firstIndex(where: { $0.id == part.id }) {
      updatedParts[partIndex] = part
    } else {
      let insertIndex = updatedParts.firstIndex(where: { $0.id > part.id }) ?? updatedParts.count
      updatedParts.insert(part, at: insertIndex)
    }

    messages[messageIndex] = MessageEnvelope(info: messages[messageIndex].info, parts: updatedParts)
    return (sessionID: part.sessionID, messages: messages)
  }

  static func messageUpdatedMutation(
    from properties: [String: JSONValue],
    messagesBySession: [String: [MessageEnvelope]]
  ) -> (sessionID: String, messages: [MessageEnvelope])? {
    let info: MessageMetadata?
    if let infoValue = properties["info"] {
      info = infoValue.decoded(as: MessageMetadata.self)
    } else {
      info = JSONValue.object(properties).decoded(as: MessageMetadata.self)
    }

    guard let info else {
      return nil
    }

    var messages = messagesBySession[info.sessionID] ?? []
    if let index = messages.firstIndex(where: { $0.info.id == info.id }) {
      let existingParts = messages[index].parts
      messages[index] = MessageEnvelope(info: info, parts: existingParts)
    } else {
      let insertIndex = messages.firstIndex(where: { $0.info.id > info.id }) ?? messages.count
      messages.insert(MessageEnvelope(info: info, parts: []), at: insertIndex)
    }

    return (sessionID: info.sessionID, messages: messages)
  }

  static func messageRemovalMutation(
    from properties: [String: JSONValue],
    messagesBySession: [String: [MessageEnvelope]]
  ) -> (sessionID: String, messages: [MessageEnvelope])? {
    guard
      let sessionID = properties.string(for: "sessionID"),
      let messageID = properties.string(for: "messageID"),
      var messages = messagesBySession[sessionID]
    else {
      return nil
    }

    let originalCount = messages.count
    messages.removeAll { $0.info.id == messageID }
    guard messages.count != originalCount else {
      return nil
    }

    return (sessionID: sessionID, messages: messages)
  }

  static func partRemovalMutation(
    from properties: [String: JSONValue],
    messagesBySession: [String: [MessageEnvelope]]
  ) -> (sessionID: String, messages: [MessageEnvelope])? {
    guard
      let sessionID = properties.string(for: "sessionID"),
      let messageID = properties.string(for: "messageID"),
      let partID = properties.string(for: "partID"),
      var messages = messagesBySession[sessionID],
      let messageIndex = messages.firstIndex(where: { $0.info.id == messageID })
    else {
      return nil
    }

    var updatedParts = messages[messageIndex].parts
    let originalCount = updatedParts.count
    updatedParts.removeAll { $0.id == partID }
    guard updatedParts.count != originalCount else {
      return nil
    }

    messages[messageIndex] = MessageEnvelope(info: messages[messageIndex].info, parts: updatedParts)
    return (sessionID: sessionID, messages: messages)
  }
}
