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

public struct ToolState: Codable, Hashable, Sendable {
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
  public let createdAt: Double?
  public let completedAt: Double?
  public let error: MessageFailure?
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
    self.summaryDiffs = summaryDiffs
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
  public let callID: String?
  public let toolState: ToolState?
  public let metadata: [String: JSONValue]?
  public let hash: String?
  public let files: [String]
  public let reason: String?
  public let attempt: Int?
  public let auto: Bool?
  public let agentName: String?
  public let subtaskPrompt: String?
  public let subtaskDescription: String?
  public let subtaskAgent: String?
  public let subtaskCommand: String?
  public let subtaskModel: ModelSelector?
  public let fileMime: String?
  public let fileName: String?
  public let fileURL: String?
  public let raw: JSONValue

  public var isContextTool: Bool {
    guard type == "tool", let tool else {
      return false
    }
    return tool == "read" || tool == "glob" || tool == "grep" || tool == "list"
  }

  public var isToolRunning: Bool {
    toolState?.status.isInFlight == true
  }

  public var toolInput: [String: JSONValue] {
    toolState?.input ?? [:]
  }

  public func toolInputString(_ key: String) -> String? {
    toolInput[key]?.stringValue
  }

  public func toolInputNumber(_ key: String) -> Double? {
    toolInput[key]?.doubleValue
  }

  public func toolInputArray(_ key: String) -> [JSONValue]? {
    toolInput[key]?.arrayValue
  }

  public func toolInputStringArray(_ key: String) -> [String] {
    toolInputArray(key)?.compactMap(\.stringValue) ?? []
  }

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
    callID = object.string(for: "callID")
    metadata = object.object(for: "metadata")

    if let stateValue = object["state"] {
      toolState = stateValue.decoded(as: ToolState.self)
    } else {
      toolState = nil
    }

    hash = object.string(for: "hash")
    files = object.array(for: "files")?.compactMap(\.stringValue) ?? []
    reason = object.string(for: "reason")
    attempt = object.int(for: "attempt")
    auto = object.bool(for: "auto")
    agentName = object.string(for: "name")

    subtaskPrompt = object.string(for: "prompt")
    subtaskDescription = object.string(for: "description")
    subtaskAgent = object.string(for: "agent")
    subtaskCommand = object.string(for: "command")

    if
      let model = object.object(for: "model"),
      let providerID = model.string(for: "providerID"),
      let modelID = model.string(for: "modelID")
    {
      subtaskModel = ModelSelector(providerID: providerID, modelID: modelID)
    } else {
      subtaskModel = nil
    }

    fileMime = object.string(for: "mime")
    fileName = object.string(for: "filename")
    fileURL = object.string(for: "url")

    self.raw = raw
  }

  public init(
    id: String,
    sessionID: String,
    messageID: String,
    type: String,
    text: String?,
    tool: String?,
    callID: String? = nil,
    toolState: ToolState? = nil,
    metadata: [String: JSONValue]? = nil,
    hash: String? = nil,
    files: [String] = [],
    reason: String? = nil,
    attempt: Int? = nil,
    auto: Bool? = nil,
    agentName: String? = nil,
    subtaskPrompt: String? = nil,
    subtaskDescription: String? = nil,
    subtaskAgent: String? = nil,
    subtaskCommand: String? = nil,
    subtaskModel: ModelSelector? = nil,
    fileMime: String? = nil,
    fileName: String? = nil,
    fileURL: String? = nil,
    raw: JSONValue
  ) {
    self.id = id
    self.sessionID = sessionID
    self.messageID = messageID
    self.type = type
    self.text = text
    self.tool = tool
    self.callID = callID
    self.toolState = toolState
    self.metadata = metadata
    self.hash = hash
    self.files = files
    self.reason = reason
    self.attempt = attempt
    self.auto = auto
    self.agentName = agentName
    self.subtaskPrompt = subtaskPrompt
    self.subtaskDescription = subtaskDescription
    self.subtaskAgent = subtaskAgent
    self.subtaskCommand = subtaskCommand
    self.subtaskModel = subtaskModel
    self.fileMime = fileMime
    self.fileName = fileName
    self.fileURL = fileURL
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
      if let tool {
        return "[Tool: \(tool)]"
      }
      return "[Tool]"
    case "step-start":
      return "[Step started]"
    case "step-finish":
      if let reason, !reason.isEmpty {
        return "[Step finished: \(reason)]"
      }
      return "[Step finished]"
    case "retry":
      if let attempt {
        return "[Retrying request #\(attempt)]"
      }
      return "[Retrying request]"
    case "compaction":
      return "[Context compacted]"
    case "patch":
      if !files.isEmpty {
        return "[Patch for \(files.count) file(s)]"
      }
      return "[Patch applied]"
    case "agent":
      if let agentName, !agentName.isEmpty {
        return "[Agent: \(agentName)]"
      }
      return "[Agent selected]"
    case "subtask":
      if let subtaskDescription, !subtaskDescription.isEmpty {
        return "[Subtask: \(subtaskDescription)]"
      }
      return "[Subtask created]"
    case "file":
      if let fileName, !fileName.isEmpty {
        return "[File: \(fileName)]"
      }
      return "[File attached]"
    default:
      return nil
    }
  }

  public func appendingDelta(field: String, delta: String) -> MessagePart? {
    guard var object = raw.objectValue else {
      return nil
    }

    guard appendDelta(delta, to: field, in: &object) else {
      return nil
    }

    return JSONValue.object(object).decoded(as: MessagePart.self)
  }
}

public enum PermissionReply: String, Codable, Hashable, Sendable {
  case once
  case always
  case reject
}

public struct PermissionToolReference: Codable, Hashable, Sendable {
  public let messageID: String
  public let callID: String

  public init(messageID: String, callID: String) {
    self.messageID = messageID
    self.callID = callID
  }
}

public struct PermissionRequest: Codable, Hashable, Identifiable, Sendable {
  public let id: String
  public let sessionID: String
  public let permission: String
  public let patterns: [String]
  public let metadata: [String: JSONValue]
  public let always: [String]
  public let tool: PermissionToolReference?

  public init(
    id: String,
    sessionID: String,
    permission: String,
    patterns: [String],
    metadata: [String: JSONValue],
    always: [String],
    tool: PermissionToolReference?
  ) {
    self.id = id
    self.sessionID = sessionID
    self.permission = permission
    self.patterns = patterns
    self.metadata = metadata
    self.always = always
    self.tool = tool
  }
}

public struct QuestionOption: Codable, Hashable, Sendable {
  public let label: String
  public let description: String

  public init(label: String, description: String) {
    self.label = label
    self.description = description
  }
}

public struct QuestionInfo: Codable, Hashable, Sendable {
  public let question: String
  public let header: String
  public let options: [QuestionOption]
  public let multiple: Bool?
  public let custom: Bool?

  public init(question: String, header: String, options: [QuestionOption], multiple: Bool?, custom: Bool?) {
    self.question = question
    self.header = header
    self.options = options
    self.multiple = multiple
    self.custom = custom
  }
}

public struct QuestionRequest: Codable, Hashable, Identifiable, Sendable {
  public let id: String
  public let sessionID: String
  public let questions: [QuestionInfo]
  public let tool: PermissionToolReference?

  public init(id: String, sessionID: String, questions: [QuestionInfo], tool: PermissionToolReference?) {
    self.id = id
    self.sessionID = sessionID
    self.questions = questions
    self.tool = tool
  }
}

public typealias QuestionAnswer = [String]

public struct PermissionReplyRequest: Encodable, Sendable {
  public let reply: PermissionReply
  public let message: String?

  public init(reply: PermissionReply, message: String? = nil) {
    self.reply = reply
    self.message = message
  }
}

public struct QuestionReplyRequest: Encodable, Sendable {
  public let answers: [QuestionAnswer]

  public init(answers: [QuestionAnswer]) {
    self.answers = answers
  }
}

public struct TodoItem: Codable, Hashable, Identifiable, Sendable {
  public let content: String
  public let status: String
  public let priority: String

  public var id: String {
    "\(content)::\(status)::\(priority)"
  }

  public init(content: String, status: String, priority: String) {
    self.content = content
    self.status = status
    self.priority = priority
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
    let info: MessageInfo?
    if let infoValue = properties["info"] {
      info = infoValue.decoded(as: MessageInfo.self)
    } else {
      info = JSONValue.object(properties).decoded(as: MessageInfo.self)
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

private func appendDelta(_ delta: String, to field: String, in object: inout [String: JSONValue]) -> Bool {
  let path = field
    .split(separator: ".")
    .map(String.init)

  guard !path.isEmpty else {
    return false
  }

  return appendDelta(delta, path: ArraySlice(path), in: &object)
}

private func appendDelta(_ delta: String, path: ArraySlice<String>, in object: inout [String: JSONValue]) -> Bool {
  guard let key = path.first else {
    return false
  }

  if path.count == 1 {
    let currentValue = object[key]?.stringValue ?? ""
    object[key] = .string(currentValue + delta)
    return true
  }

  var child = object[key]?.objectValue ?? [:]
  let didAppend = appendDelta(delta, path: path.dropFirst(), in: &child)
  object[key] = .object(child)
  return didAppend
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

public extension ServerEvent {
  func decodeProperties<T: Decodable>(as type: T.Type) -> T? {
    properties.decoded(as: type)
  }
}
