import Foundation
import OpenCodeSDK
import Testing

struct OpenCodeClientToolsTests {
  @Test func toolRoutes() async throws {
    let controller = makeSuccessPathController()
    let client = makeClient(controller: controller)

    let commands = try await client.listCommands()
    #expect(commands.first?.name == "fix")
    #expect(commands.first?.source == .command)
    #expect(commands.first?.subtask == true)

    let agents = try await client.listAgents()
    #expect(agents.first?.name == "build")

    let skills = try await client.listSkills()
    #expect(skills.first?.name == "swift-concurrency-pro")
    #expect(skills.first?.content.contains("async await") == true)

    let lspStatus = try await client.listLSPStatus()
    #expect(lspStatus.first?.id == "sourcekit-lsp")
    #expect(lspStatus.first?.status == .connected)

    let formatterStatus = try await client.listFormatterStatus()
    #expect(formatterStatus.first?.name == "swiftformat")
    #expect(formatterStatus.first?.enabled == true)

    let mcpStatus = try await client.listMCPStatus()
    #expect(mcpStatus["github"]?.status == .connected)
    #expect(mcpStatus["linear"]?.status == .needsAuth)

    let addedMCP = try await client.addMCP(
      name: "github",
      config: .remote(MCPRemoteConfiguration(url: "https://mcp.example", oauth: .disabled))
    )
    #expect(addedMCP["github"]?.status == .needsAuth)

    let mcpAuthStart = try await client.startMCPAuth(name: "github")
    #expect(mcpAuthStart.authorizationURL == "https://mcp.example/auth")

    let mcpAuthCallback = try await client.callbackMCPAuth(name: "github", code: "oauth-code")
    #expect(mcpAuthCallback.status == .connected)

    let mcpAuthenticated = try await client.authenticateMCPAuth(name: "github")
    #expect(mcpAuthenticated.status == .connected)

    let removedMCPAuth = try await client.removeMCPAuth(name: "github")
    #expect(removedMCPAuth.success == true)

    let connectedMCP = try await client.connectMCP(name: "github")
    #expect(connectedMCP == true)

    let disconnectedMCP = try await client.disconnectMCP(name: "github")
    #expect(disconnectedMCP == true)

    let requests = controller.recordedRequests
    #expect(requests.contains { $0.url?.path == "/command" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/agent" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/skill" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/lsp" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/formatter" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/mcp" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/mcp" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/mcp/github/auth" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/mcp/github/auth/callback" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/mcp/github/auth/authenticate" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/mcp/github/auth" && $0.httpMethod == "DELETE" })
    #expect(requests.contains { $0.url?.path == "/mcp/github/connect" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/mcp/github/disconnect" && $0.httpMethod == "POST" })
  }
}
