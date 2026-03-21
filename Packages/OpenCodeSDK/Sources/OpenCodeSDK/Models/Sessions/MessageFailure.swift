import Foundation

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
