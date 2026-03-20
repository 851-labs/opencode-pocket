import Foundation

public enum AuthCredential: Hashable, Sendable {
  case oauth(refresh: String, access: String, expires: Double, accountID: String?, enterpriseURL: String?)
  case api(key: String)
  case wellKnown(key: String, token: String)
}

extension AuthCredential: Codable {
  enum CodingKeys: String, CodingKey {
    case type
    case refresh
    case access
    case expires
    case accountID = "accountId"
    case enterpriseURL = "enterpriseUrl"
    case key
    case token
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(String.self, forKey: .type) {
    case "oauth":
      self = .oauth(
        refresh: try container.decode(String.self, forKey: .refresh),
        access: try container.decode(String.self, forKey: .access),
        expires: try container.decode(Double.self, forKey: .expires),
        accountID: try container.decodeIfPresent(String.self, forKey: .accountID),
        enterpriseURL: try container.decodeIfPresent(String.self, forKey: .enterpriseURL)
      )
    case "api":
      self = .api(key: try container.decode(String.self, forKey: .key))
    case "wellknown":
      self = .wellKnown(
        key: try container.decode(String.self, forKey: .key),
        token: try container.decode(String.self, forKey: .token)
      )
    default:
      throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unsupported auth type")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .oauth(refresh, access, expires, accountID, enterpriseURL):
      try container.encode("oauth", forKey: .type)
      try container.encode(refresh, forKey: .refresh)
      try container.encode(access, forKey: .access)
      try container.encode(expires, forKey: .expires)
      try container.encodeIfPresent(accountID, forKey: .accountID)
      try container.encodeIfPresent(enterpriseURL, forKey: .enterpriseURL)
    case let .api(key):
      try container.encode("api", forKey: .type)
      try container.encode(key, forKey: .key)
    case let .wellKnown(key, token):
      try container.encode("wellknown", forKey: .type)
      try container.encode(key, forKey: .key)
      try container.encode(token, forKey: .token)
    }
  }
}
