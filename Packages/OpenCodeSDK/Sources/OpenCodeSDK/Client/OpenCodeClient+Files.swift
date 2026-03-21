import Foundation

public extension OpenCodeClient {
  func listFiles(path: String, directory: String? = nil) async throws -> [FileNode] {
    var queryItems = mergedDirectoryQuery(directory)
    queryItems.append(URLQueryItem(name: "path", value: path))
    return try await request(.get, path: "/file", query: queryItems, response: [FileNode].self)
  }

  func readFile(path: String, directory: String? = nil) async throws -> FileContent {
    var queryItems = mergedDirectoryQuery(directory)
    queryItems.append(URLQueryItem(name: "path", value: path))
    return try await request(.get, path: "/file/content", query: queryItems, response: FileContent.self)
  }

  func listFileStatus(directory: String? = nil) async throws -> [FileStatusEntry] {
    try await request(.get, path: "/file/status", query: mergedDirectoryQuery(directory), response: [FileStatusEntry].self)
  }

  func getVCSInfo(directory: String? = nil) async throws -> VCSInfo {
    try await request(.get, path: "/vcs", query: mergedDirectoryQuery(directory), response: VCSInfo.self)
  }

  func findFiles(
    query searchQuery: String,
    includeDirectories: Bool? = nil,
    type: FileNodeType? = nil,
    limit: Int? = nil,
    directory: String? = nil
  ) async throws -> [String] {
    var queryItems = mergedDirectoryQuery(directory)
    queryItems.append(URLQueryItem(name: "query", value: searchQuery))
    if let includeDirectories {
      queryItems.append(URLQueryItem(name: "dirs", value: includeDirectories ? "true" : "false"))
    }
    if let type {
      queryItems.append(URLQueryItem(name: "type", value: type.rawValue))
    }
    if let limit {
      queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
    }

    return try await request(.get, path: "/find/file", query: queryItems, response: [String].self)
  }

  func findText(pattern: String, directory: String? = nil) async throws -> [TextSearchMatch] {
    var queryItems = mergedDirectoryQuery(directory)
    queryItems.append(URLQueryItem(name: "pattern", value: pattern))
    return try await request(.get, path: "/find", query: queryItems, response: [TextSearchMatch].self)
  }

  func findSymbols(query searchQuery: String, directory: String? = nil) async throws -> [WorkspaceSymbol] {
    var queryItems = mergedDirectoryQuery(directory)
    queryItems.append(URLQueryItem(name: "query", value: searchQuery))
    return try await request(.get, path: "/find/symbol", query: queryItems, response: [WorkspaceSymbol].self)
  }
}
