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

public enum ServerEventType: Hashable, Sendable {
  case serverConnected
  case serverHeartbeat
  case globalDisposed
  case projectUpdated
  case fileWatcherUpdated
  case serverInstanceDisposed
  case vcsBranchUpdated
  case sessionCreated
  case sessionUpdated
  case sessionDeleted
  case sessionIdle
  case sessionStatus
  case sessionError
  case sessionDiff
  case todoUpdated
  case permissionAsked
  case permissionReplied
  case questionAsked
  case questionReplied
  case questionRejected
  case messagePartDelta
  case messagePartUpdated
  case messagePartRemoved
  case messageUpdated
  case messageRemoved
  case lspUpdated
  case mcpToolsChanged
  case unknown(String)

  public init(rawValue: String) {
    switch rawValue {
    case "server.connected":
      self = .serverConnected
    case "server.heartbeat":
      self = .serverHeartbeat
    case "global.disposed":
      self = .globalDisposed
    case "project.updated":
      self = .projectUpdated
    case "file.watcher.updated":
      self = .fileWatcherUpdated
    case "server.instance.disposed":
      self = .serverInstanceDisposed
    case "vcs.branch.updated":
      self = .vcsBranchUpdated
    case "session.created":
      self = .sessionCreated
    case "session.updated":
      self = .sessionUpdated
    case "session.deleted":
      self = .sessionDeleted
    case "session.idle":
      self = .sessionIdle
    case "session.status":
      self = .sessionStatus
    case "session.error":
      self = .sessionError
    case "session.diff":
      self = .sessionDiff
    case "todo.updated":
      self = .todoUpdated
    case "permission.asked":
      self = .permissionAsked
    case "permission.replied":
      self = .permissionReplied
    case "question.asked":
      self = .questionAsked
    case "question.replied":
      self = .questionReplied
    case "question.rejected":
      self = .questionRejected
    case "message.part.delta":
      self = .messagePartDelta
    case "message.part.updated":
      self = .messagePartUpdated
    case "message.part.removed":
      self = .messagePartRemoved
    case "message.updated":
      self = .messageUpdated
    case "message.removed":
      self = .messageRemoved
    case "lsp.updated":
      self = .lspUpdated
    case "mcp.tools.changed":
      self = .mcpToolsChanged
    default:
      self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .serverConnected:
      return "server.connected"
    case .serverHeartbeat:
      return "server.heartbeat"
    case .globalDisposed:
      return "global.disposed"
    case .projectUpdated:
      return "project.updated"
    case .fileWatcherUpdated:
      return "file.watcher.updated"
    case .serverInstanceDisposed:
      return "server.instance.disposed"
    case .vcsBranchUpdated:
      return "vcs.branch.updated"
    case .sessionCreated:
      return "session.created"
    case .sessionUpdated:
      return "session.updated"
    case .sessionDeleted:
      return "session.deleted"
    case .sessionIdle:
      return "session.idle"
    case .sessionStatus:
      return "session.status"
    case .sessionError:
      return "session.error"
    case .sessionDiff:
      return "session.diff"
    case .todoUpdated:
      return "todo.updated"
    case .permissionAsked:
      return "permission.asked"
    case .permissionReplied:
      return "permission.replied"
    case .questionAsked:
      return "question.asked"
    case .questionReplied:
      return "question.replied"
    case .questionRejected:
      return "question.rejected"
    case .messagePartDelta:
      return "message.part.delta"
    case .messagePartUpdated:
      return "message.part.updated"
    case .messagePartRemoved:
      return "message.part.removed"
    case .messageUpdated:
      return "message.updated"
    case .messageRemoved:
      return "message.removed"
    case .lspUpdated:
      return "lsp.updated"
    case .mcpToolsChanged:
      return "mcp.tools.changed"
    case let .unknown(value):
      return value
    }
  }
}

public struct GlobalServerEvent: Decodable, Hashable, Sendable {
  public let directory: String?
  public let payload: ServerEvent

  public init(directory: String?, payload: ServerEvent) {
    self.directory = directory
    self.payload = payload
  }
}

public extension GlobalServerEvent {
  var resolvedDirectory: String {
    directory ?? "global"
  }
}

public struct ServerEvent: Decodable, Hashable, Sendable {
  public let type: String
  public let properties: JSONValue

  public init(type: String, properties: JSONValue) {
    self.type = type
    self.properties = properties
  }
}

public extension ServerEvent {
  var eventType: ServerEventType {
    ServerEventType(rawValue: type)
  }

  func decodeProperties<T: Decodable>(as type: T.Type) -> T? {
    properties.decoded(as: type)
  }
}
