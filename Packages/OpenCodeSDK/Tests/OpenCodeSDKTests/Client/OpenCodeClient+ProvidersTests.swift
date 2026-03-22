import Foundation
import OpenCodeSDK
import Testing

struct OpenCodeClientProvidersTests {
  @Test func providerRoutes() async throws {
    let controller = makeSuccessPathController()
    let client = makeClient(controller: controller)

    let providerList = try await client.listProviders()
    #expect(providerList.all.first?.id == "openai")
    #expect(providerList.connected == ["openai"])

    let authMethods = try await client.listProviderAuthMethods()
    #expect(authMethods["openai"]?.first?.type == "api")

    let oauth = try await client.authorizeProviderOAuth(providerID: "openai", method: 0, inputs: ["region": "us"])
    #expect(oauth?.url == "https://provider.example/auth")

    let oauthCallback = try await client.callbackProviderOAuth(providerID: "openai", method: 0, code: "abc123")
    #expect(oauthCallback == true)

    let authSet = try await client.setAuth(providerID: "openai", auth: .api(key: "secret"))
    #expect(authSet == true)

    let authRemoved = try await client.removeAuth(providerID: "openai")
    #expect(authRemoved == true)

    let configProviders = try await client.listConfigProviders()
    #expect(configProviders.providers.first?.id == "openai")

    let requests = controller.recordedRequests
    #expect(requests.contains { $0.url?.path == "/provider" && $0.url?.query?.contains("directory=/tmp/default") == true })
    #expect(requests.contains { $0.url?.path == "/provider/auth" && $0.url?.query?.contains("directory=/tmp/default") == true })
    #expect(requests.contains { $0.url?.path == "/provider/openai/oauth/authorize" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/provider/openai/oauth/callback" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/auth/openai" && $0.httpMethod == "PUT" })
    #expect(requests.contains { $0.url?.path == "/auth/openai" && $0.httpMethod == "DELETE" })
    #expect(requests.contains { $0.url?.path == "/config/providers" && $0.httpMethod == "GET" })
  }
}
