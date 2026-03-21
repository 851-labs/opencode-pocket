import Foundation

public enum FileContentType: String, Codable, Hashable, Sendable {
  case text
  case binary
}

public struct FilePatchHunk: Codable, Hashable, Sendable {
  public let oldStart: Int
  public let oldLines: Int
  public let newStart: Int
  public let newLines: Int
  public let lines: [String]

  public init(oldStart: Int, oldLines: Int, newStart: Int, newLines: Int, lines: [String]) {
    self.oldStart = oldStart
    self.oldLines = oldLines
    self.newStart = newStart
    self.newLines = newLines
    self.lines = lines
  }
}

public struct FilePatch: Codable, Hashable, Sendable {
  public let oldFileName: String
  public let newFileName: String
  public let oldHeader: String?
  public let newHeader: String?
  public let hunks: [FilePatchHunk]
  public let index: String?

  public init(
    oldFileName: String,
    newFileName: String,
    oldHeader: String? = nil,
    newHeader: String? = nil,
    hunks: [FilePatchHunk],
    index: String? = nil
  ) {
    self.oldFileName = oldFileName
    self.newFileName = newFileName
    self.oldHeader = oldHeader
    self.newHeader = newHeader
    self.hunks = hunks
    self.index = index
  }
}

public struct FileContent: Codable, Hashable, Sendable {
  public let type: FileContentType
  public let content: String
  public let diff: String?
  public let patch: FilePatch?
  public let encoding: String?
  public let mimeType: String?

  public init(
    type: FileContentType,
    content: String,
    diff: String? = nil,
    patch: FilePatch? = nil,
    encoding: String? = nil,
    mimeType: String? = nil
  ) {
    self.type = type
    self.content = content
    self.diff = diff
    self.patch = patch
    self.encoding = encoding
    self.mimeType = mimeType
  }
}

public enum FileStatusType: String, Codable, Hashable, Sendable {
  case added
  case deleted
  case modified
}

public struct FileStatusEntry: Codable, Hashable, Identifiable, Sendable {
  public let path: String
  public let added: Int
  public let removed: Int
  public let status: FileStatusType

  public var id: String {
    path
  }

  public init(path: String, added: Int, removed: Int, status: FileStatusType) {
    self.path = path
    self.added = added
    self.removed = removed
    self.status = status
  }
}

public struct VCSInfo: Codable, Hashable, Sendable {
  public let branch: String?

  public init(branch: String?) {
    self.branch = branch
  }
}
