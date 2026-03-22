import Foundation
import OpenCodeSDK
import Testing

struct CodableBranchCoverageTests {
  @Test func messageFailureDecodesNestedAndTopLevelMessages() throws {
    let nestedJSON = #"{"name":"ToolError","data":{"message":"nested"}}"#.data(using: .utf8)!
    let topLevelJSON = #"{"message":"top-level"}"#.data(using: .utf8)!

    let nested = try JSONDecoder().decode(MessageFailure.self, from: nestedJSON)
    let topLevel = try JSONDecoder().decode(MessageFailure.self, from: topLevelJSON)

    #expect(nested.name == "ToolError")
    #expect(nested.displayMessage == "nested")
    #expect(topLevel.name == "UnknownError")
    #expect(topLevel.displayMessage == "top-level")
  }

  @Test func messageFailureInitializerAndInvalidDecode() throws {
    let failure = MessageFailure(name: "Boom", message: nil)
    let encoded = try JSONEncoder().encode(failure)
    let decoded = try JSONDecoder().decode(MessageFailure.self, from: encoded)
    #expect(decoded.displayMessage == "Boom")

    do {
      _ = try JSONDecoder().decode(MessageFailure.self, from: Data(#""boom""#.utf8))
      Issue.record("Expected invalid MessageFailure decode to throw")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains("Message error is not an object") == true)
    }
  }

  @Test func messageTokenUsageCoversEncodeDecodeAndFallbacks() throws {
    let cache = MessageTokenUsage.CacheUsage(read: 3, write: 4)
    let usage = MessageTokenUsage(total: 20, input: 5, output: 6, reasoning: 2, cache: cache)
    let encoded = try JSONEncoder().encode(usage)
    let decoded = try JSONDecoder().decode(MessageTokenUsage.self, from: encoded)
    #expect(decoded.total == 20)
    #expect(decoded.contextUsageTotal == 20)

    let noCacheJSON = #"{"input":1,"output":2,"reasoning":3}"#.data(using: .utf8)!
    let noCache = try JSONDecoder().decode(MessageTokenUsage.self, from: noCacheJSON)
    #expect(noCache.cache == .init())

    do {
      _ = try JSONDecoder().decode(MessageTokenUsage.CacheUsage.self, from: Data(#"true"#.utf8))
      Issue.record("Expected invalid CacheUsage decode to throw")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains("Token cache usage is not an object") == true)
    }

    do {
      _ = try JSONDecoder().decode(MessageTokenUsage.self, from: Data(#"1"#.utf8))
      Issue.record("Expected invalid MessageTokenUsage decode to throw")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains("Token usage is not an object") == true)
    }
  }

  @Test func sessionStatusTypeAndSessionStatusCoverUnknownPaths() throws {
    #expect(SessionStatusType(rawValue: "idle") == .idle)
    #expect(SessionStatusType(rawValue: "busy").isRunning == true)
    #expect(SessionStatusType(rawValue: "mystery") == .unknown("mystery"))

    let encodedType = try JSONEncoder().encode(SessionStatusType.unknown("mystery"))
    let decodedType = try JSONDecoder().decode(SessionStatusType.self, from: encodedType)
    #expect(decodedType == .unknown("mystery"))

    let status = SessionStatus(type: .retry, attempt: 2, message: "Retrying", next: 42)
    #expect(status.displayLabel == "retry")
    #expect(status.isRunning == true)

    let statusData = try JSONEncoder().encode(status)
    let decodedStatus = try JSONDecoder().decode(SessionStatus.self, from: statusData)
    #expect(decodedStatus.attempt == 2)
    #expect(decodedStatus.message == "Retrying")
    #expect(decodedStatus.next == 42)
    #expect(SessionStatus.idle.type == .idle)

    let missingTypeJSON = #"{"message":"idle?"}"#.data(using: .utf8)!
    let missingType = try JSONDecoder().decode(SessionStatus.self, from: missingTypeJSON)
    #expect(missingType.type == .unknown("unknown"))

    do {
      _ = try JSONDecoder().decode(SessionStatus.self, from: Data(#"[]"#.utf8))
      Issue.record("Expected invalid SessionStatus decode to throw")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains("Session status is not an object") == true)
    }
  }

  @Test func authCredentialCoversApiWellKnownAndInvalidType() throws {
    let api = AuthCredential.api(key: "secret")
    let wellKnown = AuthCredential.wellKnown(key: "service", token: "token")

    let apiData = try JSONEncoder().encode(api)
    let wellKnownData = try JSONEncoder().encode(wellKnown)
    let decodedAPI = try JSONDecoder().decode(AuthCredential.self, from: apiData)
    let decodedWellKnown = try JSONDecoder().decode(AuthCredential.self, from: wellKnownData)

    #expect(decodedAPI == .api(key: "secret"))
    #expect(decodedWellKnown == .wellKnown(key: "service", token: "token"))

    let invalidJSON = #"{"type":"mystery"}"#.data(using: .utf8)!
    do {
      _ = try JSONDecoder().decode(AuthCredential.self, from: invalidJSON)
      Issue.record("Expected invalid AuthCredential decode to throw")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains("Unsupported auth type") == true)
    }
  }

  @Test func commandModelsCoverUnknownSourceAndDescriptorInit() throws {
    #expect(CommandSource(rawValue: "skill") == .skill)
    #expect(CommandSource(rawValue: "mystery") == .unknown("mystery"))

    let encoded = try JSONEncoder().encode(CommandSource.unknown("mystery"))
    let decoded = try JSONDecoder().decode(CommandSource.self, from: encoded)
    #expect(decoded == .unknown("mystery"))

    let descriptor = CommandDescriptor(
      name: "fix",
      description: "Fix things",
      agent: "build",
      model: "openai/gpt-5",
      source: .command,
      template: "Fix {{input}}",
      subtask: true,
      hints: ["be precise"]
    )
    #expect(descriptor.id == "fix")
    #expect(descriptor.source == .command)
  }

  @Test func mcpModelsCoverEnumCasesConfigShapesAndInitHelpers() throws {
    #expect(MCPServerConnectionState(rawValue: "disabled") == .disabled)
    #expect(MCPServerConnectionState(rawValue: "failed") == .failed)
    #expect(MCPServerConnectionState(rawValue: "needs_client_registration") == .needsClientRegistration)
    #expect(MCPServerConnectionState(rawValue: "weird") == .unknown("weird"))

    let status = MCPServerStatus(status: .failed, error: "boom")
    #expect(status.error == "boom")

    let oauthConfig = MCPOAuthConfiguration(clientID: "client", clientSecret: "secret", scope: "repo")
    let oauthData = try JSONEncoder().encode(oauthConfig)
    let oauthObject = try #require(JSONSerialization.jsonObject(with: oauthData) as? [String: Any])
    #expect(oauthObject["clientId"] as? String == "client")

    let localConfig = MCPLocalConfiguration(command: ["bun", "run"], environment: ["TOKEN": "abc"], enabled: true, timeout: 10)
    let remoteConfig = MCPRemoteConfiguration(url: "https://mcp.example", enabled: false, headers: ["Authorization": "Bearer"], oauth: .config(oauthConfig), timeout: 20)
    #expect(localConfig.command == ["bun", "run"])
    #expect(remoteConfig.url == "https://mcp.example")

    let disabledSettingData = try JSONEncoder().encode(MCPOAuthSetting.disabled)
    let disabledSettingObject = try JSONSerialization.jsonObject(with: disabledSettingData, options: .fragmentsAllowed) as? Bool
    #expect(disabledSettingObject == false)

    let decodedDisabled = try JSONDecoder().decode(MCPOAuthSetting.self, from: Data(#"false"#.utf8))
    #expect(decodedDisabled == .disabled)

    let decodedConfigured = try JSONDecoder().decode(MCPOAuthSetting.self, from: oauthData)
    #expect(decodedConfigured == .config(oauthConfig))

    let localConfiguration = MCPConfiguration.local(localConfig)
    let remoteConfiguration = MCPConfiguration.remote(remoteConfig)
    let localData = try JSONEncoder().encode(localConfiguration)
    let remoteData = try JSONEncoder().encode(remoteConfiguration)
    let localObject = try #require(JSONSerialization.jsonObject(with: localData) as? [String: Any])
    let remoteObject = try #require(JSONSerialization.jsonObject(with: remoteData) as? [String: Any])
    #expect(localObject["type"] as? String == "local")
    #expect(remoteObject["type"] as? String == "remote")

    let decodedLocal = try JSONDecoder().decode(MCPConfiguration.self, from: localData)
    let decodedRemote = try JSONDecoder().decode(MCPConfiguration.self, from: remoteData)
    #expect(decodedLocal == .local(localConfig))
    #expect(decodedRemote == .remote(remoteConfig))

    let addRequest = MCPAddRequest(name: "github", config: remoteConfiguration)
    #expect(addRequest.name == "github")

    let startResponse = MCPOAuthStartResponse(authorizationURL: "https://mcp.example/auth")
    #expect(startResponse.authorizationURL == "https://mcp.example/auth")

    let callbackRequest = MCPOAuthCallbackRequest(code: "oauth-code")
    #expect(callbackRequest.code == "oauth-code")

    let removeResponse = MCPOAuthRemoveResponse(success: true)
    #expect(removeResponse.success == true)
  }
}
