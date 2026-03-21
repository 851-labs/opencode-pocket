import Foundation

public extension OpenCodeClient {
  func listProviders(directory: String? = nil) async throws -> ProviderListResponse {
    try await request(.get, path: "/provider", query: mergedDirectoryQuery(directory), response: ProviderListResponse.self)
  }

  func listProviderAuthMethods(directory: String? = nil) async throws -> ProviderAuthMethodResponse {
    try await request(.get, path: "/provider/auth", query: mergedDirectoryQuery(directory), response: ProviderAuthMethodResponse.self)
  }

  func authorizeProviderOAuth(
    providerID: String,
    method: Int,
    inputs: [String: String]? = nil,
    directory: String? = nil
  ) async throws -> ProviderOAuthAuthorization? {
    try await request(
      .post,
      path: "/provider/\(escapedPathComponent(providerID))/oauth/authorize",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(ProviderOAuthAuthorizeRequest(method: method, inputs: inputs)),
      response: ProviderOAuthAuthorization?.self
    )
  }

  func callbackProviderOAuth(
    providerID: String,
    method: Int,
    code: String? = nil,
    directory: String? = nil
  ) async throws -> Bool {
    try await request(
      .post,
      path: "/provider/\(escapedPathComponent(providerID))/oauth/callback",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(ProviderOAuthCallbackRequest(method: method, code: code)),
      response: Bool.self
    )
  }

  func setAuth(providerID: String, auth: AuthCredential) async throws -> Bool {
    try await request(
      .put,
      path: "/auth/\(escapedPathComponent(providerID))",
      body: AnyEncodable(auth),
      response: Bool.self
    )
  }

  func removeAuth(providerID: String) async throws -> Bool {
    try await request(.delete, path: "/auth/\(escapedPathComponent(providerID))", response: Bool.self)
  }

  func listConfigProviders(directory: String? = nil) async throws -> ProviderCatalogResponse {
    try await request(.get, path: "/config/providers", query: mergedDirectoryQuery(directory), response: ProviderCatalogResponse.self)
  }
}
