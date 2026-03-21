import Foundation

public extension OpenCodeClient {
  func listProjects() async throws -> [ProjectInfo] {
    try await request(.get, path: "/project", response: [ProjectInfo].self)
  }

  func getCurrentProject(directory: String? = nil) async throws -> ProjectInfo {
    try await request(.get, path: "/project/current", query: mergedDirectoryQuery(directory), response: ProjectInfo.self)
  }

  func initializeProjectGit(directory: String? = nil) async throws -> ProjectInfo {
    try await request(.post, path: "/project/git/init", query: mergedDirectoryQuery(directory), response: ProjectInfo.self)
  }

  func updateProject(id: String, body: ProjectUpdateRequest, directory: String? = nil) async throws -> ProjectInfo {
    try await request(
      .patch,
      path: "/project/\(escapedPathComponent(id))",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(body),
      response: ProjectInfo.self
    )
  }
}
