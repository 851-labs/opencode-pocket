import Foundation

public struct MessagePart: Codable, Hashable, Identifiable, Sendable {
  public let id: String
  public let sessionID: String
  public let messageID: String
  public let type: String
  public let text: String?
  public let tool: String?
  public let callID: String?
  public let toolState: ToolExecutionState?
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
      toolState = stateValue.decoded(as: ToolExecutionState.self)
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
    toolState: ToolExecutionState? = nil,
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
