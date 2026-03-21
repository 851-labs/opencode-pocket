import Foundation

public extension OpenCodeClient {
  func health() async throws -> HealthResponse {
    try await request(.get, path: "/global/health", response: HealthResponse.self)
  }

  func getGlobalConfig() async throws -> OpenCodeConfig {
    try await request(.get, path: "/global/config", response: OpenCodeConfig.self)
  }

  func updateGlobalConfig(_ config: OpenCodeConfig) async throws -> OpenCodeConfig {
    try await request(.patch, path: "/global/config", body: AnyEncodable(config), response: OpenCodeConfig.self)
  }

  func disposeGlobal() async throws -> Bool {
    try await request(.post, path: "/global/dispose", response: Bool.self)
  }

  func disposeInstance(directory: String? = nil) async throws -> Bool {
    try await request(.post, path: "/instance/dispose", query: mergedDirectoryQuery(directory), response: Bool.self)
  }

  func getConfig(directory: String? = nil) async throws -> OpenCodeConfig {
    try await request(.get, path: "/config", query: mergedDirectoryQuery(directory), response: OpenCodeConfig.self)
  }

  func updateConfig(_ config: OpenCodeConfig, directory: String? = nil) async throws -> OpenCodeConfig {
    try await request(
      .patch,
      path: "/config",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(config),
      response: OpenCodeConfig.self
    )
  }

  func getPath() async throws -> PathInfo {
    try await request(.get, path: "/path", response: PathInfo.self)
  }
}
