import Foundation

public struct ProviderOAuthAuthorization: Codable, Hashable, Sendable {
  public let url: String
  public let method: String
  public let instructions: String

  public init(url: String, method: String, instructions: String) {
    self.url = url
    self.method = method
    self.instructions = instructions
  }
}

public struct ProviderOAuthAuthorizeRequest: Encodable, Sendable {
  public let method: Int
  public let inputs: [String: String]?

  public init(method: Int, inputs: [String: String]? = nil) {
    self.method = method
    self.inputs = inputs
  }
}

public struct ProviderOAuthCallbackRequest: Encodable, Sendable {
  public let method: Int
  public let code: String?

  public init(method: Int, code: String? = nil) {
    self.method = method
    self.code = code
  }
}

public struct ProjectUpdateRequest: Encodable, Sendable {
  public let name: String?
  public let icon: ProjectIcon?
  public let commands: ProjectCommands?

  public init(name: String? = nil, icon: ProjectIcon? = nil, commands: ProjectCommands? = nil) {
    self.name = name
    self.icon = icon
    self.commands = commands
  }
}
