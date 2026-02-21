import Foundation

public enum JSONValue: Codable, Hashable, Sendable {
  case string(String)
  case number(Double)
  case bool(Bool)
  case object([String: JSONValue])
  case array([JSONValue])
  case null

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
      return
    }
    if let value = try? container.decode(Bool.self) {
      self = .bool(value)
      return
    }
    if let value = try? container.decode(Int.self) {
      self = .number(Double(value))
      return
    }
    if let value = try? container.decode(Double.self) {
      self = .number(value)
      return
    }
    if let value = try? container.decode(String.self) {
      self = .string(value)
      return
    }
    if let value = try? container.decode([String: JSONValue].self) {
      self = .object(value)
      return
    }
    if let value = try? container.decode([JSONValue].self) {
      self = .array(value)
      return
    }
    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON type")
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case let .string(value):
      try container.encode(value)
    case let .number(value):
      try container.encode(value)
    case let .bool(value):
      try container.encode(value)
    case let .object(value):
      try container.encode(value)
    case let .array(value):
      try container.encode(value)
    case .null:
      try container.encodeNil()
    }
  }
}

public extension JSONValue {
  var objectValue: [String: JSONValue]? {
    guard case let .object(value) = self else { return nil }
    return value
  }

  var arrayValue: [JSONValue]? {
    guard case let .array(value) = self else { return nil }
    return value
  }

  var stringValue: String? {
    guard case let .string(value) = self else { return nil }
    return value
  }

  var boolValue: Bool? {
    guard case let .bool(value) = self else { return nil }
    return value
  }

  var doubleValue: Double? {
    guard case let .number(value) = self else { return nil }
    return value
  }

  var compactDescription: String {
    switch self {
    case let .string(value):
      return value
    case let .number(value):
      return String(value)
    case let .bool(value):
      return value ? "true" : "false"
    case let .array(values):
      return values.map(\.compactDescription).joined(separator: ", ")
    case let .object(object):
      if
        let message = object["message"]?.stringValue,
        !message.isEmpty
      {
        return message
      }
      let pairs = object.map { key, value in "\(key): \(value.compactDescription)" }
      return "{\(pairs.sorted().joined(separator: ", "))}"
    case .null:
      return "null"
    }
  }
}

public extension Dictionary where Key == String, Value == JSONValue {
  func string(for key: String) -> String? {
    self[key]?.stringValue
  }

  func object(for key: String) -> [String: JSONValue]? {
    self[key]?.objectValue
  }
}
