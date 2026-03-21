import Foundation

public struct PromptRequest: Encodable, Sendable {
  public var messageID: String?
  public var model: ModelSelector?
  public var agent: String?
  public var noReply: Bool?
  public var system: String?
  public var variant: String?
  public var parts: [PromptInputPart]

  public init(
    messageID: String? = nil,
    model: ModelSelector? = nil,
    agent: String? = nil,
    noReply: Bool? = nil,
    system: String? = nil,
    variant: String? = nil,
    parts: [PromptInputPart]
  ) {
    self.messageID = messageID
    self.model = model
    self.agent = agent
    self.noReply = noReply
    self.system = system
    self.variant = variant
    self.parts = parts
  }
}

public enum PromptInputPart: Encodable, Hashable, Sendable {
  case text(TextPartInput)
  case file(FilePartInput)
  case agent(AgentPartInput)
  case subtask(SubtaskPartInput)

  public func encode(to encoder: Encoder) throws {
    switch self {
    case let .text(value):
      try value.encode(to: encoder)
    case let .file(value):
      try value.encode(to: encoder)
    case let .agent(value):
      try value.encode(to: encoder)
    case let .subtask(value):
      try value.encode(to: encoder)
    }
  }

  public static func text(_ text: String) -> PromptInputPart {
    .text(TextPartInput(text: text))
  }
}

public struct TextPartInput: Encodable, Hashable, Sendable {
  public let type: String
  public let text: String

  public init(text: String) {
    type = "text"
    self.text = text
  }
}

public struct FilePartInput: Encodable, Hashable, Sendable {
  public let id: String?
  public let type: String
  public let mime: String
  public let filename: String?
  public let url: String
  public let source: JSONValue?

  public init(id: String? = nil, mime: String, filename: String?, url: String, source: JSONValue? = nil) {
    self.id = id
    type = "file"
    self.mime = mime
    self.filename = filename
    self.url = url
    self.source = source
  }
}

public struct AgentPartInput: Encodable, Hashable, Sendable {
  public let type: String
  public let name: String

  public init(name: String) {
    type = "agent"
    self.name = name
  }
}

public struct SubtaskPartInput: Encodable, Hashable, Sendable {
  public let type: String
  public let prompt: String
  public let description: String
  public let agent: String
  public let model: ModelSelector?
  public let command: String?

  public init(prompt: String, description: String, agent: String, model: ModelSelector?, command: String?) {
    type = "subtask"
    self.prompt = prompt
    self.description = description
    self.agent = agent
    self.model = model
    self.command = command
  }
}
