import Foundation

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
