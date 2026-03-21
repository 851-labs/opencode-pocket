import Foundation

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
  public let mode: String?
  public let variant: String?
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
    mode = object.string(for: "mode")
    variant = object.string(for: "variant")

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
    mode: String? = nil,
    variant: String? = nil,
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
    self.mode = mode
    self.variant = variant
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
