import Foundation
import OpenCodeSDK
import Testing

struct OpenCodeClientGlobalTests {
  @Test func globalRoutes() async throws {
    let controller = makeSuccessPathController()
    let client = makeClient(controller: controller)

    let health = try await client.health()
    #expect(health.healthy == true)
    #expect(health.version == "1.2.3")

    let globalConfig = try await client.getGlobalConfig()
    #expect(globalConfig["model"]?.stringValue == "openai/gpt-5")

    let updatedGlobalConfig = try await client.updateGlobalConfig([
      "model": .string("anthropic/claude-sonnet-4"),
      "disabled_providers": .array([.string("demo"), .string("test")]),
    ])
    #expect(updatedGlobalConfig["disabled_providers"]?.arrayValue?.count == 2)

    let disposedGlobal = try await client.disposeGlobal()
    #expect(disposedGlobal == true)

    let disposedInstance = try await client.disposeInstance()
    #expect(disposedInstance == true)

    let pathInfo = try await client.getPath()
    #expect(pathInfo.home == "/Users/opencode")

    let config = try await client.getConfig()
    #expect(config["default_agent"]?.stringValue == "build")

    let updatedConfig = try await client.updateConfig([
      "model": .string("openai/gpt-5"),
      "default_agent": .string("fast"),
    ])
    #expect(updatedConfig["default_agent"]?.stringValue == "fast")

    let requests = controller.recordedRequests
    #expect(requests.contains { $0.url?.path == "/global/health" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/global/config" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/global/config" && $0.httpMethod == "PATCH" })
    #expect(requests.contains { $0.url?.path == "/global/dispose" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/instance/dispose" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/instance/dispose" && $0.url?.query?.contains("directory=/tmp/default") == true })
    #expect(requests.contains { $0.url?.path == "/path" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/config" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/config" && $0.httpMethod == "PATCH" })
  }
}
