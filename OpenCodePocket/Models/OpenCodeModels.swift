import Foundation

struct HealthResponse: Decodable, Equatable, Sendable {
    let healthy: Bool
    let version: String
}

struct ModelSelector: Codable, Hashable, Sendable {
    let providerID: String
    let modelID: String
}

struct SessionTime: Codable, Hashable, Sendable {
    let created: Double?
    let updated: Double?
    let archived: Double?
}

struct Session: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let slug: String
    let projectID: String
    let directory: String
    let parentID: String?
    let title: String
    let version: String
    let time: SessionTime
    let summary: JSONValue?
    let share: JSONValue?
    let revert: JSONValue?

    var sortTimestamp: Double {
        time.updated ?? time.created ?? 0
    }
}

struct SessionCreateRequest: Encodable, Sendable {
    var parentID: String?
    var title: String?
}

struct SessionUpdateRequest: Encodable, Sendable {
    var title: String?
    var time: SessionUpdateTime?
}

struct SessionUpdateTime: Encodable, Sendable {
    var archived: Double?
}

struct MessageEnvelope: Codable, Hashable, Identifiable, Sendable {
    let info: MessageInfo
    let parts: [MessagePart]

    var id: String { info.id }

    var textBody: String {
        let merged = parts
            .compactMap(\.renderedText)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !merged.isEmpty {
            return merged
        }
        return info.role == .assistant ? "(Assistant response has no text parts yet)" : "(No text content)"
    }
}

enum MessageRole: String, Codable, Hashable, Sendable {
    case user
    case assistant
    case unknown
}

struct MessageInfo: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let sessionID: String
    let role: MessageRole
    let agent: String?
    let providerID: String?
    let modelID: String?
    let parentID: String?
    let raw: JSONValue

    init(from decoder: Decoder) throws {
        let raw = try JSONValue(from: decoder)
        guard let object = raw.objectValue else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Message info is not an object"))
        }

        guard let id = object.string(for: "id"), let sessionID = object.string(for: "sessionID") else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Message info missing id or sessionID"))
        }

        self.id = id
        self.sessionID = sessionID
        self.role = MessageRole(rawValue: object.string(for: "role") ?? "") ?? .unknown
        self.agent = object.string(for: "agent")
        self.parentID = object.string(for: "parentID")

        let nestedModel = object.object(for: "model")
        self.providerID = object.string(for: "providerID") ?? nestedModel?.string(for: "providerID")
        self.modelID = object.string(for: "modelID") ?? nestedModel?.string(for: "modelID")
        self.raw = raw
    }

    func encode(to encoder: Encoder) throws {
        try raw.encode(to: encoder)
    }
}

struct MessagePart: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let sessionID: String
    let messageID: String
    let type: String
    let text: String?
    let tool: String?
    let raw: JSONValue

    init(from decoder: Decoder) throws {
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
        self.text = object.string(for: "text")
        self.tool = object.string(for: "tool")
        self.raw = raw
    }

    func encode(to encoder: Encoder) throws {
        try raw.encode(to: encoder)
    }

    var renderedText: String? {
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
}

struct PromptRequest: Encodable, Sendable {
    var messageID: String?
    var model: ModelSelector?
    var agent: String?
    var noReply: Bool?
    var system: String?
    var variant: String?
    var parts: [PromptInputPart]

    init(
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

enum PromptInputPart: Encodable, Hashable, Sendable {
    case text(TextPartInput)
    case file(FilePartInput)
    case agent(AgentPartInput)
    case subtask(SubtaskPartInput)

    func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let value):
            try value.encode(to: encoder)
        case .file(let value):
            try value.encode(to: encoder)
        case .agent(let value):
            try value.encode(to: encoder)
        case .subtask(let value):
            try value.encode(to: encoder)
        }
    }

    static func text(_ text: String) -> PromptInputPart {
        .text(TextPartInput(text: text))
    }
}

struct TextPartInput: Encodable, Hashable, Sendable {
    let type = "text"
    let text: String
}

struct FilePartInput: Encodable, Hashable, Sendable {
    let type = "file"
    let mime: String
    let filename: String?
    let url: String
}

struct AgentPartInput: Encodable, Hashable, Sendable {
    let type = "agent"
    let name: String
}

struct SubtaskPartInput: Encodable, Hashable, Sendable {
    let type = "subtask"
    let prompt: String
    let description: String
    let agent: String
    let model: ModelSelector?
    let command: String?
}

struct ServerEvent: Decodable, Hashable, Sendable {
    let type: String
    let properties: JSONValue
}
