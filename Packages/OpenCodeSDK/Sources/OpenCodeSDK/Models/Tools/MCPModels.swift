import Foundation

public enum MCPServerConnectionState: Hashable, Sendable {
  case connected
  case disabled
  case failed
  case needsAuth
  case needsClientRegistration
  case unknown(String)

  public init(rawValue: String) {
    switch rawValue {
    case "connected":
      self = .connected
    case "disabled":
      self = .disabled
    case "failed":
      self = .failed
    case "needs_auth":
      self = .needsAuth
    case "needs_client_registration":
      self = .needsClientRegistration
    default:
      self = .unknown(rawValue)
    }
  }

  public var rawValue: String {
    switch self {
    case .connected:
      return "connected"
    case .disabled:
      return "disabled"
    case .failed:
      return "failed"
    case .needsAuth:
      return "needs_auth"
    case .needsClientRegistration:
      return "needs_client_registration"
    case let .unknown(value):
      return value
    }
  }
}

extension MCPServerConnectionState: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self = MCPServerConnectionState(rawValue: try container.decode(String.self))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

public struct MCPServerStatus: Codable, Hashable, Sendable {
  public let status: MCPServerConnectionState
  public let error: String?

  public init(status: MCPServerConnectionState, error: String? = nil) {
    self.status = status
    self.error = error
  }
}

public struct MCPOAuthConfiguration: Codable, Hashable, Sendable {
  public let clientID: String?
  public let clientSecret: String?
  public let scope: String?

  enum CodingKeys: String, CodingKey {
    case clientID = "clientId"
    case clientSecret
    case scope
  }

  public init(clientID: String? = nil, clientSecret: String? = nil, scope: String? = nil) {
    self.clientID = clientID
    self.clientSecret = clientSecret
    self.scope = scope
  }
}

public struct MCPLocalConfiguration: Codable, Hashable, Sendable {
  public let command: [String]
  public let environment: [String: String]?
  public let enabled: Bool?
  public let timeout: Int?

  public init(command: [String], environment: [String: String]? = nil, enabled: Bool? = nil, timeout: Int? = nil) {
    self.command = command
    self.environment = environment
    self.enabled = enabled
    self.timeout = timeout
  }
}

public struct MCPRemoteConfiguration: Codable, Hashable, Sendable {
  public let url: String
  public let enabled: Bool?
  public let headers: [String: String]?
  public let oauth: MCPOAuthSetting?
  public let timeout: Int?

  public init(
    url: String,
    enabled: Bool? = nil,
    headers: [String: String]? = nil,
    oauth: MCPOAuthSetting? = nil,
    timeout: Int? = nil
  ) {
    self.url = url
    self.enabled = enabled
    self.headers = headers
    self.oauth = oauth
    self.timeout = timeout
  }
}

public enum MCPOAuthSetting: Hashable, Sendable {
  case config(MCPOAuthConfiguration)
  case disabled
}

extension MCPOAuthSetting: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let disabled = try? container.decode(Bool.self), disabled == false {
      self = .disabled
      return
    }
    self = .config(try container.decode(MCPOAuthConfiguration.self))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case let .config(config):
      try container.encode(config)
    case .disabled:
      try container.encode(false)
    }
  }
}

public enum MCPConfiguration: Hashable, Sendable {
  case local(MCPLocalConfiguration)
  case remote(MCPRemoteConfiguration)
}

extension MCPConfiguration: Codable {
  enum CodingKeys: String, CodingKey {
    case type
  }

  enum Kind: String, Codable {
    case local
    case remote
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Kind.self, forKey: .type) {
    case .local:
      self = .local(try MCPLocalConfiguration(from: decoder))
    case .remote:
      self = .remote(try MCPRemoteConfiguration(from: decoder))
    }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case let .local(config):
      var keyed = encoder.container(keyedBy: CodingKeys.self)
      try keyed.encode(Kind.local, forKey: .type)
      try config.encode(to: encoder)
    case let .remote(config):
      var keyed = encoder.container(keyedBy: CodingKeys.self)
      try keyed.encode(Kind.remote, forKey: .type)
      try config.encode(to: encoder)
    }
  }
}

public struct MCPAddRequest: Encodable, Sendable {
  public let name: String
  public let config: MCPConfiguration

  public init(name: String, config: MCPConfiguration) {
    self.name = name
    self.config = config
  }
}

public struct MCPOAuthStartResponse: Codable, Hashable, Sendable {
  public let authorizationURL: String

  enum CodingKeys: String, CodingKey {
    case authorizationURL = "authorizationUrl"
  }

  public init(authorizationURL: String) {
    self.authorizationURL = authorizationURL
  }
}

public struct MCPOAuthCallbackRequest: Encodable, Sendable {
  public let code: String

  public init(code: String) {
    self.code = code
  }
}

public struct MCPOAuthRemoveResponse: Codable, Hashable, Sendable {
  public let success: Bool

  public init(success: Bool) {
    self.success = success
  }
}
