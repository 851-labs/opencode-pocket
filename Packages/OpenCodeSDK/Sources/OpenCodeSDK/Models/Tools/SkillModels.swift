import Foundation

public struct SkillInfo: Codable, Hashable, Identifiable, Sendable {
  public let name: String
  public let description: String
  public let location: String
  public let content: String

  public var id: String {
    name
  }

  public init(name: String, description: String, location: String, content: String) {
    self.name = name
    self.description = description
    self.location = location
    self.content = content
  }
}
