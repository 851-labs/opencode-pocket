import Foundation

enum HTTPMethod: String {
  case get = "GET"
  case post = "POST"
  case patch = "PATCH"
  case delete = "DELETE"
  case put = "PUT"
}

struct HTTPRequestBuilder {
  let baseURL: URL
  let basicAuthHeader: String?

  init(baseURL: URL, username: String?, password: String?) {
    self.baseURL = baseURL
    if let username, let password {
      let credentials = Data("\(username):\(password)".utf8).base64EncodedString()
      basicAuthHeader = "Basic \(credentials)"
    } else {
      basicAuthHeader = nil
    }
  }

  func makeRequest(
    path: String,
    method: HTTPMethod,
    query: [URLQueryItem] = [],
    body: Data? = nil,
    timeout: TimeInterval = 60
  ) throws -> URLRequest {
    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
      throw OpenCodeClientError.invalidURL(baseURL.absoluteString)
    }

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

    guard let finalURL = components.url else {
      throw OpenCodeClientError.invalidURL(baseURL.absoluteString + normalizedPath)
    }

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

    return request
  }
}
