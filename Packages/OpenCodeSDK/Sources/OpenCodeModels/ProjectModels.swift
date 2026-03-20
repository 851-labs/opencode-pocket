import Foundation

public struct ProjectInfo: Codable, Hashable, Identifiable, Sendable {
  public let id: String
  public let worktree: String
  public let vcs: String?
  public let name: String?
  public let icon: ProjectIcon?
  public let commands: ProjectCommands?
  public let time: ProjectTime
  public let sandboxes: [String]

  public init(
    id: String,
    worktree: String,
    vcs: String?,
    name: String?,
    icon: ProjectIcon?,
    commands: ProjectCommands?,
    time: ProjectTime,
    sandboxes: [String]
  ) {
    self.id = id
    self.worktree = worktree
    self.vcs = vcs
    self.name = name
    self.icon = icon
    self.commands = commands
    self.time = time
    self.sandboxes = sandboxes
  }
}

public struct ProjectIcon: Codable, Hashable, Sendable {
  public let url: String?
  public let override: String?
  public let color: String?

  public init(url: String?, override: String?, color: String?) {
    self.url = url
    self.override = override
    self.color = color
  }
}

public struct ProjectCommands: Codable, Hashable, Sendable {
  public let start: String?

  public init(start: String?) {
    self.start = start
  }
}

public struct ProjectTime: Codable, Hashable, Sendable {
  public let created: Double
  public let updated: Double
  public let initialized: Double?

  public init(created: Double, updated: Double, initialized: Double? = nil) {
    self.created = created
    self.updated = updated
    self.initialized = initialized
  }
}
