import Foundation
import OpenCodeModels
import OpenCodeNetworking

@MainActor
extension WorkspaceStore {
  func fetchServerBrowseRootDirectory() async throws -> String {
    guard let client = connection.client else {
      throw OpenCodeClientError.message("Connect to a server before browsing directories.")
    }

    let pathInfo = try await client.getPath()
    guard
      let root = pathInfo.home.trimmedNonEmpty
        ?? pathInfo.directory.trimmedNonEmpty
        ?? pathInfo.worktree.trimmedNonEmpty
    else {
      throw OpenCodeClientError.message("Server did not return a usable root directory.")
    }

    return Self.standardizedServerPath(root)
  }

  func listServerDirectory(path directory: String) async throws -> [FileNode] {
    guard let client = connection.client else {
      throw OpenCodeClientError.message("Connect to a server before browsing directories.")
    }

    let normalizedDirectory = Self.standardizedServerPath(directory)
    let nodes = try await client.listFiles(path: "", directory: normalizedDirectory)
    return nodes.sorted { lhs, rhs in
      if lhs.type != rhs.type {
        return lhs.type == .directory
      }
      return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
  }

  func searchServerDirectories(path directory: String, query: String, limit: Int = 50) async throws -> [String] {
    guard let client = connection.client else {
      throw OpenCodeClientError.message("Connect to a server before browsing directories.")
    }

    let normalizedDirectory = Self.standardizedServerPath(directory)
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedQuery.isEmpty else {
      return []
    }

    let matches = try await client.findFiles(
      query: trimmedQuery,
      includeDirectories: true,
      type: .directory,
      limit: limit,
      directory: normalizedDirectory
    )

    var seen: Set<String> = []
    var resolved: [String] = []
    for item in matches {
      let absolute = Self.resolveServerSearchPath(item, rootDirectory: normalizedDirectory)
      if seen.insert(absolute).inserted {
        resolved.append(absolute)
      }
    }

    return resolved.sorted { lhs, rhs in
      lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
    }
  }

  private static func resolveServerSearchPath(_ candidate: String, rootDirectory: String) -> String {
    let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return rootDirectory
    }

    let expanded = (trimmed as NSString).expandingTildeInPath
    if expanded.hasPrefix("/") {
      return standardizedServerPath(expanded)
    }

    return URL(fileURLWithPath: expanded, relativeTo: URL(fileURLWithPath: rootDirectory)).standardizedFileURL.path
  }

  private static func standardizedServerPath(_ raw: String) -> String {
    let expanded = (raw as NSString).expandingTildeInPath
    return URL(fileURLWithPath: expanded).standardizedFileURL.path
  }
}
