import Foundation

public enum CommandSource: Hashable, Sendable {
  case command
  case mcp
  case skill
  case unknown(String)

  public init(rawValue: String) {
    switch rawValue {
    case "command":
      self = .command
    case "mcp":
      self = .mcp
    case "skill":
      self = .skill
    default:
      self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .command:
      return "command"
    case .mcp:
      return "mcp"
    case .skill:
      return "skill"
    case let .unknown(value):
      return value
    }
  }
}

extension CommandSource: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = CommandSource(rawValue: try container.decode(String.self))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public struct CommandDescriptor: Codable, Hashable, Identifiable, Sendable {
  public let name: String
  public let description: String?
  public let agent: String?
  public let model: String?
  public let source: CommandSource?
  public let template: String
  public let subtask: Bool?
  public let hints: [String]

  public var id: String {
    name
  }

  public init(
    name: String,
    description: String?,
    agent: String?,
    model: String?,
    source: CommandSource?,
    template: String,
    subtask: Bool?,
    hints: [String]
  ) {
    self.name = name
    self.description = description
    self.agent = agent
    self.model = model
    self.source = source
    self.template = template
    self.subtask = subtask
    self.hints = hints
  }
}

public enum LSPServerConnectionState: Hashable, Sendable {
  case connected
  case error
  case unknown(String)

  public init(rawValue: String) {
    switch rawValue {
    case "connected":
      self = .connected
    case "error":
      self = .error
    default:
      self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .connected:
      return "connected"
    case .error:
      return "error"
    case let .unknown(value):
      return value
    }
  }
}

extension LSPServerConnectionState: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = LSPServerConnectionState(rawValue: try container.decode(String.self))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public struct LSPServerStatus: Codable, Hashable, Identifiable, Sendable {
  public let id: String
  public let name: String
  public let root: String
  public let status: LSPServerConnectionState

  public init(id: String, name: String, root: String, status: LSPServerConnectionState) {
    self.id = id
    self.name = name
    self.root = root
    self.status = status
  }
}

public enum MCPServerConnectionState: Hashable, Sendable {
  case connected
  case disabled
  case failed
  case needsAuth
  case needsClientRegistration
  case unknown(String)

  public init(rawValue: String) {
    switch rawValue {
    case "connected":
      self = .connected
    case "disabled":
      self = .disabled
    case "failed":
      self = .failed
    case "needs_auth":
      self = .needsAuth
    case "needs_client_registration":
      self = .needsClientRegistration
    default:
      self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .connected:
      return "connected"
    case .disabled:
      return "disabled"
    case .failed:
      return "failed"
    case .needsAuth:
      return "needs_auth"
    case .needsClientRegistration:
      return "needs_client_registration"
    case let .unknown(value):
      return value
    }
  }
}

extension MCPServerConnectionState: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = MCPServerConnectionState(rawValue: try container.decode(String.self))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public struct MCPServerStatus: Codable, Hashable, Sendable {
  public let status: MCPServerConnectionState
  public let error: String?

  public init(status: MCPServerConnectionState, error: String? = nil) {
    self.status = status
    self.error = error
  }
}

public enum ToolExecutionStatus: Hashable, Sendable {
  case pending
  case running
  case completed
  case error
  case unknown(String)

  public var rawValue: String {
    switch self {
    case .pending:
      return "pending"
    case .running:
      return "running"
    case .completed:
      return "completed"
    case .error:
      return "error"
    case let .unknown(value):
      return value
    }
  }

  public var isInFlight: Bool {
    switch self {
    case .pending, .running:
      return true
    default:
      return false
    }
  }

  public init(rawValue: String) {
    switch rawValue {
    case "pending":
      self = .pending
    case "running":
      self = .running
    case "completed":
      self = .completed
    case "error":
      self = .error
    default:
      self = .unknown(rawValue)
    }
  }
}

extension ToolExecutionStatus: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let value = try container.decode(String.self)

    switch value {
    case "pending":
      self = .pending
    case "running":
      self = .running
    case "completed":
      self = .completed
    case "error":
      self = .error
    default:
      self = .unknown(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public struct ToolExecutionTime: Codable, Hashable, Sendable {
  public let start: Double?
  public let end: Double?
  public let compacted: Double?

  public init(start: Double?, end: Double?, compacted: Double?) {
    self.start = start
    self.end = end
    self.compacted = compacted
  }
}

public struct ToolExecutionState: Codable, Hashable, Sendable {
  public let status: ToolExecutionStatus
  public let input: [String: JSONValue]
  public let output: String?
  public let title: String?
  public let error: String?
  public let metadata: [String: JSONValue]?
  public let time: ToolExecutionTime?
  public let raw: JSONValue

  public init(from decoder: Decoder) throws {
    let raw = try JSONValue(from: decoder)
    guard let object = raw.objectValue else {
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Tool state is not an object"))
    }

    status = ToolExecutionStatus(rawValue: object.string(for: "status") ?? "unknown")
    input = object.object(for: "input") ?? [:]
    output = object.string(for: "output")
    title = object.string(for: "title")
    error = object.string(for: "error")
    metadata = object.object(for: "metadata")

    if let timeObject = object.object(for: "time") {
      time = ToolExecutionTime(
        start: timeObject.double(for: "start"),
        end: timeObject.double(for: "end"),
        compacted: timeObject.double(for: "compacted")
      )
    } else {
      time = nil
    }

    self.raw = raw
  }

  public init(
    status: ToolExecutionStatus,
    input: [String: JSONValue],
    output: String?,
    title: String?,
    error: String?,
    metadata: [String: JSONValue]?,
    time: ToolExecutionTime?
  ) {
    self.status = status
    self.input = input
    self.output = output
    self.title = title
    self.error = error
    self.metadata = metadata
    self.time = time

    var object: [String: JSONValue] = [
      "status": .string(status.rawValue),
      "input": .object(input),
    ]
    if let output {
      object["output"] = .string(output)
    }
    if let title {
      object["title"] = .string(title)
    }
    if let error {
      object["error"] = .string(error)
    }
    if let metadata {
      object["metadata"] = .object(metadata)
    }
    if let time {
      var timeObject: [String: JSONValue] = [:]
      if let start = time.start {
        timeObject["start"] = .number(start)
      }
      if let end = time.end {
        timeObject["end"] = .number(end)
      }
      if let compacted = time.compacted {
        timeObject["compacted"] = .number(compacted)
      }
      object["time"] = .object(timeObject)
    }
    raw = .object(object)
  }

  public func encode(to encoder: Encoder) throws {
    try raw.encode(to: encoder)
  }
}
