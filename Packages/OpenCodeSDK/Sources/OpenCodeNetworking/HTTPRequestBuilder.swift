import Foundation

public enum HTTPMethod: String {
  case get = "GET"
  case post = "POST"
  case patch = "PATCH"
  case delete = "DELETE"
  case put = "PUT"
}

public struct HTTPRequestBuilder {
  public let baseURL: URL
  public let basicAuthHeader: String?

  public init(baseURL: URL, username: String?, password: String?) {
    self.baseURL = baseURL
    if let username, let password {
      let credentials = Data("\(username):\(password)".utf8).base64EncodedString()
      basicAuthHeader = "Basic \(credentials)"
    } else {
      basicAuthHeader = nil
    }
  }

  public func makeRequest(
    path: String,
    method: HTTPMethod,
    query: [URLQueryItem] = [],
    body: Data? = nil,
    timeout: TimeInterval = 60,
    headers: [String: String] = [:]
  ) throws -> URLRequest {
    guard baseURL.scheme != nil, baseURL.host != nil else {
      throw OpenCodeClientError.invalidURL(baseURL.absoluteString)
    }

    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!

    let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
    let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    if basePath.isEmpty {
      components.path = normalizedPath
    } else {
      components.path = "/\(basePath)\(normalizedPath)"
    }

    if !query.isEmpty {
      components.queryItems = query
    }

    let finalURL = components.url!

    var request = URLRequest(url: finalURL, timeoutInterval: timeout)
    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if let body {
      request.httpBody = body
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    if let basicAuthHeader {
      request.setValue(basicAuthHeader, forHTTPHeaderField: "Authorization")
    }

    for (name, value) in headers {
      request.setValue(value, forHTTPHeaderField: name)
    }

    return request
  }
}
