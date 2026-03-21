import Foundation

public struct FormatterStatus: Codable, Hashable, Identifiable, Sendable {
  public let name: String
  public let extensions: [String]
  public let enabled: Bool

  public var id: String {
    name
  }

  public init(name: String, extensions: [String], enabled: Bool) {
    self.name = name
    self.extensions = extensions
    self.enabled = enabled
  }
}
