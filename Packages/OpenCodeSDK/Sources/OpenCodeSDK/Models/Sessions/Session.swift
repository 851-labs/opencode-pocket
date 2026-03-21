import Foundation

public struct SessionTimestamps: Codable, Hashable, Sendable {
  public let created: Double?
  public let updated: Double?
  public let archived: Double?

  public init(created: Double?, updated: Double?, archived: Double? = nil) {
    self.created = created
    self.updated = updated
    self.archived = archived
  }
}

public struct Session: Codable, Hashable, Identifiable, Sendable {
  public let id: String
  public let slug: String
  public let projectID: String
  public let directory: String
  public let parentID: String?
  public let title: String
  public let version: String
  public let time: SessionTimestamps
  public let summary: JSONValue?
  public let share: JSONValue?
  public let revert: JSONValue?

  public var sortTimestamp: Double {
    time.updated ?? time.created ?? 0
  }

  public init(
    id: String,
    slug: String,
    projectID: String,
    directory: String,
    parentID: String?,
    title: String,
    version: String,
    time: SessionTimestamps,
    summary: JSONValue? = nil,
    share: JSONValue? = nil,
    revert: JSONValue? = nil
  ) {
    self.id = id
    self.slug = slug
    self.projectID = projectID
    self.directory = directory
    self.parentID = parentID
    self.title = title
    self.version = version
    self.time = time
    self.summary = summary
    self.share = share
    self.revert = revert
  }
}
