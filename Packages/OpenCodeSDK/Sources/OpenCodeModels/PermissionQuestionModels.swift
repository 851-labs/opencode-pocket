import Foundation

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
