import Foundation

public struct HealthResponse: Decodable, Equatable, Sendable {
  public let healthy: Bool
  public let version: String

  public init(healthy: Bool, version: String) {
    self.healthy = healthy
    self.version = version
  }
}

public struct OpenCodePage<Item: Sendable>: Sendable {
  public let items: [Item]
  public let nextCursor: String?
  public let nextURL: URL?

  public var hasNextPage: Bool {
    nextCursor != nil || nextURL != nil
  }

  public init(items: [Item], nextCursor: String? = nil, nextURL: URL? = nil) {
    self.items = items
    self.nextCursor = nextCursor
    self.nextURL = nextURL
  }
}

public struct ModelSelector: Codable, Hashable, Sendable {
  public let providerID: String
  public let modelID: String

  public init(providerID: String, modelID: String) {
    self.providerID = providerID
    self.modelID = modelID
  }
}

public struct FileDiff: Codable, Hashable, Identifiable, Sendable {
  public let file: String
  public let before: String
  public let after: String
  public let additions: Double
  public let deletions: Double
  public let status: String?

  public var id: String {
    "\(file)::\(before)::\(after)"
  }

  public var additionsCount: Int {
    Int(additions.rounded())
  }

  public var deletionsCount: Int {
    Int(deletions.rounded())
  }

  public init(file: String, before: String, after: String, additions: Double, deletions: Double, status: String?) {
    self.file = file
    self.before = before
    self.after = after
    self.additions = additions
    self.deletions = deletions
    self.status = status
  }
}

public struct PathInfo: Codable, Hashable, Sendable {
  public let home: String
  public let state: String
  public let config: String
  public let worktree: String
  public let directory: String

  public init(home: String, state: String, config: String, worktree: String, directory: String) {
    self.home = home
    self.state = state
    self.config = config
    self.worktree = worktree
    self.directory = directory
  }
}

public enum FileNodeType: String, Codable, Hashable, Sendable {
  case file
  case directory
}

public struct FileNode: Codable, Hashable, Identifiable, Sendable {
  public let name: String
  public let path: String
  public let absolute: String
  public let type: FileNodeType
  public let ignored: Bool

  public var id: String {
    absolute
  }

  public init(name: String, path: String, absolute: String, type: FileNodeType, ignored: Bool) {
    self.name = name
    self.path = path
    self.absolute = absolute
    self.type = type
    self.ignored = ignored
  }
}
