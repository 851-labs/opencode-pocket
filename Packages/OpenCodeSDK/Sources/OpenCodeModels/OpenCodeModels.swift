import Foundation

public struct HealthResponse: Decodable, Equatable, Sendable {
  public let healthy: Bool
  public let version: String

  public init(healthy: Bool, version: String) {
    self.healthy = healthy
    self.version = version
  }
}

public struct ModelSelector: Codable, Hashable, Sendable {
  public let providerID: String
  public let modelID: String

  public init(providerID: String, modelID: String) {
    self.providerID = providerID
    self.modelID = modelID
  }
}

public struct SessionTime: Codable, Hashable, Sendable {
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
  public let time: SessionTime
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
    time: SessionTime,
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

public struct FileDiff: Codable, Hashable, Identifiable, Sendable {
  public let file: String
  public let before: String
  public let after: String
  public let additions: Double
  public let deletions: Double
  public let status: String?

  public var id: String {
    "\(file)::\(before)::\(after)"
  }

  public var additionsCount: Int {
    Int(additions.rounded())
  }

  public var deletionsCount: Int {
    Int(deletions.rounded())
  }

  public init(file: String, before: String, after: String, additions: Double, deletions: Double, status: String?) {
    self.file = file
    self.before = before
    self.after = after
    self.additions = additions
    self.deletions = deletions
    self.status = status
  }
}

public struct AgentDescriptor: Codable, Hashable, Identifiable, Sendable {
  public let name: String
  public let description: String?
  public let mode: String
  public let hidden: Bool?

  public var id: String {
    name
  }

  public init(name: String, description: String?, mode: String, hidden: Bool?) {
    self.name = name
    self.description = description
    self.mode = mode
    self.hidden = hidden
  }
}

public struct ProviderCatalogResponse: Decodable, Sendable {
  public let providers: [ProviderDescriptor]
  public let defaultModels: [String: String]

  enum CodingKeys: String, CodingKey {
    case providers
    case defaultModels = "default"
  }

  public init(providers: [ProviderDescriptor], defaultModels: [String: String]) {
    self.providers = providers
    self.defaultModels = defaultModels
  }
}

public struct ProviderDescriptor: Decodable, Hashable, Sendable {
  public let id: String
  public let name: String
  public let models: [String: ProviderModelDescriptor]

  public init(id: String, name: String, models: [String: ProviderModelDescriptor]) {
    self.id = id
    self.name = name
    self.models = models
  }
}

public struct ProviderModelDescriptor: Decodable, Hashable, Sendable {
  public let id: String
  public let providerID: String
  public let name: String
  public let variants: [String: JSONValue]?

  public init(id: String, providerID: String, name: String, variants: [String: JSONValue]?) {
    self.id = id
    self.providerID = providerID
    self.name = name
    self.variants = variants
  }
}

public struct ModelOption: Hashable, Identifiable, Sendable {
  public let providerID: String
  public let providerName: String
  public let modelID: String
  public let modelName: String
  public let variants: [String]

  public var id: String {
    "\(providerID)::\(modelID)"
  }

  public var selector: ModelSelector {
    ModelSelector(providerID: providerID, modelID: modelID)
  }

  public var displayLabel: String {
    if variants.isEmpty {
      return modelName
    }
    return "\(modelName) (\(variants.count) variants)"
  }

  public init(providerID: String, providerName: String, modelID: String, modelName: String, variants: [String]) {
    self.providerID = providerID
    self.providerName = providerName
    self.modelID = modelID
    self.modelName = modelName
    self.variants = variants
  }
}

public struct ModelProviderGroup: Hashable, Identifiable, Sendable {
  public let providerID: String
  public let providerName: String
  public let models: [ModelOption]

  public var id: String {
    providerID
  }

  public init(providerID: String, providerName: String, models: [ModelOption]) {
    self.providerID = providerID
    self.providerName = providerName
    self.models = models
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

  public init(archived: Double? = nil) {
    self.archived = archived
  }
}

public struct MessageEnvelope: Codable, Hashable, Identifiable, Sendable {
  public let info: MessageInfo
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

  public init(info: MessageInfo, parts: [MessagePart]) {
    self.info = info
    self.parts = parts
  }
}

public enum MessageRole: String, Codable, Hashable, Sendable {
  case user
  case assistant
  case unknown
}

public struct MessageInfo: Codable, Hashable, Identifiable, Sendable {
  public let id: String
  public let sessionID: String
  public let role: MessageRole
  public let agent: String?
  public let providerID: String?
  public let modelID: String?
  public let parentID: String?
  public let raw: JSONValue

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

    let nestedModel = object.object(for: "model")
    providerID = object.string(for: "providerID") ?? nestedModel?.string(for: "providerID")
    modelID = object.string(for: "modelID") ?? nestedModel?.string(for: "modelID")
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
    raw: JSONValue
  ) {
    self.id = id
    self.sessionID = sessionID
    self.role = role
    self.agent = agent
    self.providerID = providerID
    self.modelID = modelID
    self.parentID = parentID
    self.raw = raw
  }

  public func encode(to encoder: Encoder) throws {
    try raw.encode(to: encoder)
  }
}

public struct MessagePart: Codable, Hashable, Identifiable, Sendable {
  public let id: String
  public let sessionID: String
  public let messageID: String
  public let type: String
  public let text: String?
  public let tool: String?
  public let raw: JSONValue

  public init(from decoder: Decoder) throws {
    let raw = try JSONValue(from: decoder)
    guard let object = raw.objectValue else {
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Message part is not an object"))
    }

    guard
      let id = object.string(for: "id"),
      let sessionID = object.string(for: "sessionID"),
      let messageID = object.string(for: "messageID"),
      let type = object.string(for: "type")
    else {
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Message part missing required fields"))
    }

    self.id = id
    self.sessionID = sessionID
    self.messageID = messageID
    self.type = type
    text = object.string(for: "text")
    tool = object.string(for: "tool")
    self.raw = raw
  }

  public init(
    id: String,
    sessionID: String,
    messageID: String,
    type: String,
    text: String?,
    tool: String?,
    raw: JSONValue
  ) {
    self.id = id
    self.sessionID = sessionID
    self.messageID = messageID
    self.type = type
    self.text = text
    self.tool = tool
    self.raw = raw
  }

  public func encode(to encoder: Encoder) throws {
    try raw.encode(to: encoder)
  }

  public var renderedText: String? {
    switch type {
    case "text", "reasoning":
      return text
    case "tool":
      return "[Tool: \(tool ?? "unknown")]"
    case "step-start":
      return "[Step started]"
    case "step-finish":
      return "[Step finished]"
    case "retry":
      return "[Retrying request]"
    case "compaction":
      return "[Context compacted]"
    default:
      return nil
    }
  }

  public func appendingDelta(field: String, delta: String) -> MessagePart? {
    guard var object = raw.objectValue else {
      return nil
    }

    let currentValue = object[field]?.stringValue ?? ""
    let nextValue = currentValue + delta
    object[field] = .string(nextValue)

    let nextText = field == "text" ? nextValue : text
    let nextTool = field == "tool" ? nextValue : tool

    return MessagePart(
      id: id,
      sessionID: sessionID,
      messageID: messageID,
      type: type,
      text: nextText,
      tool: nextTool,
      raw: .object(object)
    )
  }
}

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
  public let type: String
  public let mime: String
  public let filename: String?
  public let url: String

  public init(mime: String, filename: String?, url: String) {
    type = "file"
    self.mime = mime
    self.filename = filename
    self.url = url
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

public struct ServerEvent: Decodable, Hashable, Sendable {
  public let type: String
  public let properties: JSONValue

  public init(type: String, properties: JSONValue) {
    self.type = type
    self.properties = properties
  }
}
