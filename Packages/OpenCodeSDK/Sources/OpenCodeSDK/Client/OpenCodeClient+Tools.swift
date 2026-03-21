import Foundation

public extension OpenCodeClient {
  func listCommands() async throws -> [CommandDescriptor] {
    try await request(.get, path: "/command", response: [CommandDescriptor].self)
  }

  func listAgents(directory: String? = nil) async throws -> [AgentDescriptor] {
    try await request(.get, path: "/agent", query: mergedDirectoryQuery(directory), response: [AgentDescriptor].self)
  }

  func listSkills(directory: String? = nil) async throws -> [SkillInfo] {
    try await request(.get, path: "/skill", query: mergedDirectoryQuery(directory), response: [SkillInfo].self)
  }

  func listLSPStatus(directory: String? = nil) async throws -> [LSPServerStatus] {
    try await request(.get, path: "/lsp", query: mergedDirectoryQuery(directory), response: [LSPServerStatus].self)
  }

  func listFormatterStatus(directory: String? = nil) async throws -> [FormatterStatus] {
    try await request(.get, path: "/formatter", query: mergedDirectoryQuery(directory), response: [FormatterStatus].self)
  }

  func listMCPStatus(directory: String? = nil) async throws -> [String: MCPServerStatus] {
    try await request(.get, path: "/mcp", query: mergedDirectoryQuery(directory), response: [String: MCPServerStatus].self)
  }

  func addMCP(name: String, config: MCPConfiguration, directory: String? = nil) async throws -> [String: MCPServerStatus] {
    try await request(
      .post,
      path: "/mcp",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(MCPAddRequest(name: name, config: config)),
      response: [String: MCPServerStatus].self
    )
  }

  func startMCPAuth(name: String, directory: String? = nil) async throws -> MCPOAuthStartResponse {
    try await request(
      .post,
      path: "/mcp/\(escapedPathComponent(name))/auth",
      query: mergedDirectoryQuery(directory),
      response: MCPOAuthStartResponse.self
    )
  }

  func callbackMCPAuth(name: String, code: String, directory: String? = nil) async throws -> MCPServerStatus {
    try await request(
      .post,
      path: "/mcp/\(escapedPathComponent(name))/auth/callback",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(MCPOAuthCallbackRequest(code: code)),
      response: MCPServerStatus.self
    )
  }

  func authenticateMCPAuth(name: String, directory: String? = nil) async throws -> MCPServerStatus {
    try await request(
      .post,
      path: "/mcp/\(escapedPathComponent(name))/auth/authenticate",
      query: mergedDirectoryQuery(directory),
      response: MCPServerStatus.self
    )
  }

  func removeMCPAuth(name: String, directory: String? = nil) async throws -> MCPOAuthRemoveResponse {
    try await request(
      .delete,
      path: "/mcp/\(escapedPathComponent(name))/auth",
      query: mergedDirectoryQuery(directory),
      response: MCPOAuthRemoveResponse.self
    )
  }

  func connectMCP(name: String, directory: String? = nil) async throws -> Bool {
    try await request(
      .post,
      path: "/mcp/\(escapedPathComponent(name))/connect",
      query: mergedDirectoryQuery(directory),
      response: Bool.self
    )
  }

  func disconnectMCP(name: String, directory: String? = nil) async throws -> Bool {
    try await request(
      .post,
      path: "/mcp/\(escapedPathComponent(name))/disconnect",
      query: mergedDirectoryQuery(directory),
      response: Bool.self
    )
  }
}
