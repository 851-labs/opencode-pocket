import Foundation

public struct SessionTimestamps: Codable, Hashable, Sendable {
  public let created: Double?
  public let updated: Double?
  public let archived: Double?

  public init(created: Double?, updated: Double?, archived: Double? = nil) {
    self.created = created
    self.updated = updated
    self.archived = archived
  }
}

public struct Session: Codable, Hashable, Identifiable, Sendable {
  public let id: String
  public let slug: String
  public let projectID: String
  public let directory: String
  public let parentID: String?
  public let title: String
  public let version: String
  public let time: SessionTimestamps
  public let summary: JSONValue?
  public let share: JSONValue?
  public let revert: JSONValue?

  public var sortTimestamp: Double {
    time.updated ?? time.created ?? 0
  }

  public init(
    id: String,
    slug: String,
    projectID: String,
    directory: String,
    parentID: String?,
    title: String,
    version: String,
    time: SessionTimestamps,
    summary: JSONValue? = nil,
    share: JSONValue? = nil,
    revert: JSONValue? = nil
  ) {
    self.id = id
    self.slug = slug
    self.projectID = projectID
    self.directory = directory
    self.parentID = parentID
    self.title = title
    self.version = version
    self.time = time
    self.summary = summary
    self.share = share
    self.revert = revert
  }
}

public struct SessionCreateRequest: Encodable, Sendable {
  public var parentID: String?
  public var title: String?

  public init(parentID: String? = nil, title: String? = nil) {
    self.parentID = parentID
    self.title = title
  }
}

public struct SessionUpdateRequest: Encodable, Sendable {
  public var title: String?
  public var time: SessionUpdateTime?

  public init(title: String? = nil, time: SessionUpdateTime? = nil) {
    self.title = title
    self.time = time
  }
}

public struct SessionUpdateTime: Encodable, Sendable {
  public var archived: Double?
  private var shouldEncodeArchivedNull: Bool

  public init(archived: Double? = nil) {
    self.init(archived: archived, shouldEncodeArchivedNull: false)
  }

  public static func clearArchived() -> SessionUpdateTime {
    SessionUpdateTime(archived: nil, shouldEncodeArchivedNull: true)
  }

  enum CodingKeys: String, CodingKey {
    case archived
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    if shouldEncodeArchivedNull {
      try container.encodeNil(forKey: .archived)
      return
    }

    if let archived {
      try container.encode(archived, forKey: .archived)
    }
  }

  private init(archived: Double?, shouldEncodeArchivedNull: Bool) {
    self.archived = archived
    self.shouldEncodeArchivedNull = shouldEncodeArchivedNull
  }
}

public struct SessionCommandRequest: Encodable, Sendable {
  public var messageID: String?
  public var agent: String?
  public var model: String?
  public var arguments: String
  public var command: String
  public var variant: String?
  public var parts: [FilePartInput]?

  public init(
    messageID: String? = nil,
    agent: String? = nil,
    model: String? = nil,
    arguments: String,
    command: String,
    variant: String? = nil,
    parts: [FilePartInput]? = nil
  ) {
    self.messageID = messageID
    self.agent = agent
    self.model = model
    self.arguments = arguments
    self.command = command
    self.variant = variant
    self.parts = parts
  }
}

public struct SessionShellRequest: Encodable, Sendable {
  public var agent: String
  public var model: ModelSelector?
  public var command: String

  public init(agent: String, model: ModelSelector? = nil, command: String) {
    self.agent = agent
    self.model = model
    self.command = command
  }
}

public struct SessionRevertRequest: Encodable, Sendable {
  public var messageID: String
  public var partID: String?

  public init(messageID: String, partID: String? = nil) {
    self.messageID = messageID
    self.partID = partID
  }
}

public struct SessionSummarizeRequest: Encodable, Sendable {
  public var providerID: String
  public var modelID: String
  public var auto: Bool?

  public init(providerID: String, modelID: String, auto: Bool? = nil) {
    self.providerID = providerID
    self.modelID = modelID
    self.auto = auto
  }
}

public struct SessionInitializeRequest: Encodable, Sendable {
  public var providerID: String
  public var modelID: String
  public var messageID: String

  public init(providerID: String, modelID: String, messageID: String) {
    self.providerID = providerID
    self.modelID = modelID
    self.messageID = messageID
  }
}

public struct SessionForkRequest: Encodable, Sendable {
  public var messageID: String?

  public init(messageID: String? = nil) {
    self.messageID = messageID
  }
}

public enum SessionStatusType: Hashable, Sendable {
  case idle
  case busy
  case retry
  case unknown(String)

  public var rawValue: String {
    switch self {
    case .idle:
      return "idle"
    case .busy:
      return "busy"
    case .retry:
      return "retry"
    case let .unknown(value):
      return value
    }
  }

  public var displayLabel: String {
    rawValue
  }

  public var isRunning: Bool {
    switch self {
    case .busy, .retry:
      return true
    default:
      return false
    }
  }

  public init(rawValue: String) {
    switch rawValue {
    case "idle":
      self = .idle
    case "busy":
      self = .busy
    case "retry":
      self = .retry
    default:
      self = .unknown(rawValue)
    }
  }
}

extension SessionStatusType: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let value = try container.decode(String.self)

    switch value {
    case "idle":
      self = .idle
    case "busy":
      self = .busy
    case "retry":
      self = .retry
    default:
      self = .unknown(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public struct SessionStatus: Codable, Hashable, Sendable {
  public static let idle = SessionStatus(type: .idle)

  public let type: SessionStatusType
  public let attempt: Int?
  public let message: String?
  public let next: Double?
  public let raw: JSONValue

  public var displayLabel: String {
    type.displayLabel
  }

  public var isRunning: Bool {
    type.isRunning
  }

  public init(type: SessionStatusType, attempt: Int? = nil, message: String? = nil, next: Double? = nil) {
    self.type = type
    self.attempt = attempt
    self.message = message
    self.next = next

    var object: [String: JSONValue] = [
      "type": .string(type.rawValue),
    ]
    if let attempt {
      object["attempt"] = .number(Double(attempt))
    }
    if let message {
      object["message"] = .string(message)
    }
    if let next {
      object["next"] = .number(next)
    }
    raw = .object(object)
  }

  public init(from decoder: Decoder) throws {
    let raw = try JSONValue(from: decoder)
    guard let object = raw.objectValue else {
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Session status is not an object"))
    }

    type = SessionStatusType(rawValue: object.string(for: "type") ?? "unknown")
    attempt = object.int(for: "attempt")
    message = object.string(for: "message")
    next = object.double(for: "next")
    self.raw = raw
  }

  public func encode(to encoder: Encoder) throws {
    try raw.encode(to: encoder)
  }
}
