import Foundation

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
