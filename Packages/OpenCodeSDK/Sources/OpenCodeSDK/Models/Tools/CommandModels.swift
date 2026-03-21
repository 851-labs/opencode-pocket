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
