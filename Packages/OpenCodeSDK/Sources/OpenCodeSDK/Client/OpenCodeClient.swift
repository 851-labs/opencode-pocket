import Foundation

public struct OpenCodeClientConfiguration: Sendable {
  public let baseURL: URL
  public let username: String?
  public let password: String?
  public let directory: String?

  public init(baseURL: URL, username: String?, password: String?, directory: String?) {
    self.baseURL = baseURL
    self.username = username
    self.password = password
    self.directory = directory
  }
}

public final class OpenCodeClient {
  let configuration: OpenCodeClientConfiguration
  let requestBuilder: HTTPRequestBuilder
  let urlSession: URLSession

  public init(configuration: OpenCodeClientConfiguration, urlSession: URLSession = .shared) {
    self.configuration = configuration
    requestBuilder = HTTPRequestBuilder(
      baseURL: configuration.baseURL,
      username: configuration.username,
      password: configuration.password
    )
    self.urlSession = urlSession
  }
}
