import Foundation

public struct MessageTokenUsage: Codable, Hashable, Sendable {
  public struct CacheUsage: Codable, Hashable, Sendable {
    public let read: Int
    public let write: Int

    public init(read: Int = 0, write: Int = 0) {
      self.read = read
      self.write = write
    }

    public init(from decoder: Decoder) throws {
      let raw = try JSONValue(from: decoder)
      guard let object = raw.objectValue else {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Token cache usage is not an object"))
      }

      read = object.int(for: "read") ?? 0
      write = object.int(for: "write") ?? 0
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(read, forKey: .read)
      try container.encode(write, forKey: .write)
    }

    private enum CodingKeys: String, CodingKey {
      case read
      case write
    }
  }

  public let total: Int?
  public let input: Int
  public let output: Int
  public let reasoning: Int
  public let cache: CacheUsage

  public var contextUsageTotal: Int {
    input + output + reasoning + cache.read + cache.write
  }

  public init(total: Int? = nil, input: Int = 0, output: Int = 0, reasoning: Int = 0, cache: CacheUsage = CacheUsage()) {
    self.total = total
    self.input = input
    self.output = output
    self.reasoning = reasoning
    self.cache = cache
  }

  public init(from decoder: Decoder) throws {
    let raw = try JSONValue(from: decoder)
    guard let object = raw.objectValue else {
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Token usage is not an object"))
    }

    total = object.int(for: "total")
    input = object.int(for: "input") ?? 0
    output = object.int(for: "output") ?? 0
    reasoning = object.int(for: "reasoning") ?? 0

    if let cacheObject = object.object(for: "cache") {
      cache = CacheUsage(read: cacheObject.int(for: "read") ?? 0, write: cacheObject.int(for: "write") ?? 0)
    } else {
      cache = CacheUsage()
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(total, forKey: .total)
    try container.encode(input, forKey: .input)
    try container.encode(output, forKey: .output)
    try container.encode(reasoning, forKey: .reasoning)
    try container.encode(cache, forKey: .cache)
  }

  private enum CodingKeys: String, CodingKey {
    case total
    case input
    case output
    case reasoning
    case cache
  }
}

public struct MessageFailure: Codable, Hashable, Sendable {
  public let name: String
  public let message: String?
  public let raw: JSONValue

  public var displayMessage: String {
    if let message, !message.isEmpty {
      return message
    }
    return name
  }

  public init(from decoder: Decoder) throws {
    let raw = try JSONValue(from: decoder)
    guard let object = raw.objectValue else {
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Message error is not an object"))
    }

    name = object.string(for: "name") ?? "UnknownError"
    message = object.object(for: "data")?.string(for: "message") ?? object.string(for: "message")
    self.raw = raw
  }

  public init(name: String, message: String?) {
    self.name = name
    self.message = message

    var object: [String: JSONValue] = [
      "name": .string(name),
    ]
    if let message {
      object["data"] = .object(["message": .string(message)])
    }
    raw = .object(object)
  }

  public func encode(to encoder: Encoder) throws {
    try raw.encode(to: encoder)
  }
}

public struct MessageEnvelope: Codable, Hashable, Identifiable, Sendable {
  public let info: MessageMetadata
  public let parts: [MessagePart]

  public var id: String { info.id }

  public var textBody: String {
    let merged = parts
      .compactMap(\.renderedText)
      .joined(separator: "\n")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if !merged.isEmpty {
      return merged
    }
    return info.role == .assistant ? "(Assistant response has no text parts yet)" : "(No text content)"
  }

  public init(info: MessageMetadata, parts: [MessagePart]) {
    self.info = info
    self.parts = parts
  }
}

public enum MessageRole: String, Codable, Hashable, Sendable {
  case user
  case assistant
  case unknown
}

public struct MessageMetadata: Codable, Hashable, Identifiable, Sendable {
  public let id: String
  public let sessionID: String
  public let role: MessageRole
  public let agent: String?
  public let providerID: String?
  public let modelID: String?
  public let parentID: String?
  public let createdAt: Double?
  public let completedAt: Double?
  public let error: MessageFailure?
  public let cost: Double?
  public let tokenUsage: MessageTokenUsage?
  public let summaryDiffs: [FileDiff]
  public let raw: JSONValue

  public var errorDisplayText: String? {
    error?.displayMessage
  }

  public init(from decoder: Decoder) throws {
    let raw = try JSONValue(from: decoder)
    guard let object = raw.objectValue else {
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Message info is not an object"))
    }

    guard let id = object.string(for: "id"), let sessionID = object.string(for: "sessionID") else {
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Message info missing id or sessionID"))
    }

    self.id = id
    self.sessionID = sessionID
    role = MessageRole(rawValue: object.string(for: "role") ?? "") ?? .unknown
    agent = object.string(for: "agent")
    parentID = object.string(for: "parentID")

    let time = object.object(for: "time")
    createdAt = time?.double(for: "created")
    completedAt = time?.double(for: "completed")

    let nestedModel = object.object(for: "model")
    providerID = object.string(for: "providerID") ?? nestedModel?.string(for: "providerID")
    modelID = object.string(for: "modelID") ?? nestedModel?.string(for: "modelID")

    if let errorValue = object["error"] {
      error = errorValue.decoded(as: MessageFailure.self)
    } else {
      error = nil
    }

    cost = object.double(for: "cost")
    tokenUsage = object["tokens"]?.decoded(as: MessageTokenUsage.self)

    if
      let summary = object.object(for: "summary"),
      let diffsValue = summary["diffs"],
      let decodedDiffs = diffsValue.decoded(as: [FileDiff].self)
    {
      summaryDiffs = decodedDiffs
    } else {
      summaryDiffs = []
    }

    self.raw = raw
  }

  public init(
    id: String,
    sessionID: String,
    role: MessageRole,
    agent: String?,
    providerID: String?,
    modelID: String?,
    parentID: String?,
    createdAt: Double? = nil,
    completedAt: Double? = nil,
    error: MessageFailure? = nil,
    cost: Double? = nil,
    tokenUsage: MessageTokenUsage? = nil,
    summaryDiffs: [FileDiff] = [],
    raw: JSONValue
  ) {
    self.id = id
    self.sessionID = sessionID
    self.role = role
    self.agent = agent
    self.providerID = providerID
    self.modelID = modelID
    self.parentID = parentID
    self.createdAt = createdAt
    self.completedAt = completedAt
    self.error = error
    self.cost = cost
    self.tokenUsage = tokenUsage
    self.summaryDiffs = summaryDiffs
    self.raw = raw
  }

  public func encode(to encoder: Encoder) throws {
    try raw.encode(to: encoder)
  }
}

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
