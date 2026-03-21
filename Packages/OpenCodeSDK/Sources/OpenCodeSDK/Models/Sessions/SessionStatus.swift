import Foundation

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
