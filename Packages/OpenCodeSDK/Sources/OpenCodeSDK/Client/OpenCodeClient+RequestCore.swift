import Foundation

extension OpenCodeClient {
  func request<T: Decodable & Sendable>(
    _ method: HTTPMethod,
    path: String,
    query: [URLQueryItem] = [],
    body: AnyEncodable? = nil,
    response type: T.Type
  ) async throws -> T {
    do {
      let (data, _) = try await performRequest(method, path: path, query: query, body: body)

      do {
        return try await Self.decodeResponse(type, from: data)
      } catch {
        throw OpenCodeClientError.decoding(error)
      }
    } catch let error as OpenCodeClientError {
      throw error
    } catch {
      throw OpenCodeClientError.transport(error)
    }
  }

  func requestPage<T: Decodable & Sendable>(
    _ method: HTTPMethod,
    path: String,
    query: [URLQueryItem] = [],
    body: AnyEncodable? = nil,
    response type: T.Type
  ) async throws -> OpenCodePage<T> {
    do {
      let (data, response) = try await performRequest(method, path: path, query: query, body: body)

      do {
        let items = try await Self.decodeResponse([T].self, from: data)
        return OpenCodePage(
          items: items,
          nextCursor: response.value(forHTTPHeaderField: "X-Next-Cursor")?.trimmedNonEmpty,
          nextURL: parseNextURL(from: response.value(forHTTPHeaderField: "Link"))
        )
      } catch {
        throw OpenCodeClientError.decoding(error)
      }
    } catch let error as OpenCodeClientError {
      throw error
    } catch {
      throw OpenCodeClientError.transport(error)
    }
  }

  func requestNoContent(
    _ method: HTTPMethod,
    path: String,
    query: [URLQueryItem] = [],
    body: AnyEncodable? = nil
  ) async throws {
    do {
      _ = try await performRequest(method, path: path, query: query, body: body)
    } catch let error as OpenCodeClientError {
      throw error
    } catch {
      throw OpenCodeClientError.transport(error)
    }
  }

  func performRequest(
    _ method: HTTPMethod,
    path: String,
    query: [URLQueryItem] = [],
    body: AnyEncodable? = nil,
    headers: [String: String] = [:]
  ) async throws -> (Data, HTTPURLResponse) {
    let bodyData = try encodeBody(body)
    let request = try requestBuilder.makeRequest(path: path, method: method, query: query, body: bodyData, headers: headers)
    let (data, response) = try await urlSession.data(for: request)
    let httpResponse = try validatedHTTPResponse(from: response)

    guard (200 ..< 300).contains(httpResponse.statusCode) else {
      throw parseHTTPError(code: httpResponse.statusCode, data: data)
    }

    return (data, httpResponse)
  }

  func validatedHTTPResponse(from response: URLResponse) throws -> HTTPURLResponse {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw OpenCodeClientError.invalidResponse
    }
    return httpResponse
  }

  func encodeBody(_ body: AnyEncodable?) throws -> Data? {
    guard let body else { return nil }
    do {
      return try JSONEncoder().encode(body)
    } catch {
      throw OpenCodeClientError.message("Failed to encode request body: \(error.localizedDescription)")
    }
  }

  func parseHTTPError(code: Int, data: Data) -> OpenCodeClientError {
    if let notFound = try? JSONDecoder().decode(APINotFoundEnvelope.self, from: data) {
      let message = notFound.data.message ?? "Not found"
      return .httpStatus(code: code, message: message)
    }

    if let badRequest = try? JSONDecoder().decode(APIBadRequestEnvelope.self, from: data) {
      if let firstError = badRequest.errors?.first {
        return .httpStatus(code: code, message: firstError.compactDescription)
      }
      return .httpStatus(code: code, message: badRequest.data?.compactDescription)
    }

    if let raw = String(data: data, encoding: .utf8), !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return .httpStatus(code: code, message: raw)
    }

    return .httpStatus(code: code, message: nil)
  }

  @concurrent
  static func decodeResponse<T: Decodable & Sendable>(_ type: T.Type, from data: Data) async throws -> T {
    try JSONDecoder().decode(type, from: data)
  }

  func escapedPathComponent(_ value: String) -> String {
    value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
  }

  func mergedDirectoryQuery(_ override: String?) -> [URLQueryItem] {
    let resolved = (override?.trimmedNonEmpty) ?? configuration.directory?.trimmedNonEmpty
    guard let resolved else {
      return []
    }
    return [URLQueryItem(name: "directory", value: resolved)]
  }

  func parseNextURL(from linkHeader: String?) -> URL? {
    guard let linkHeader else {
      return nil
    }

    for item in linkHeader.split(separator: ",") {
      let value = String(item).trimmingCharacters(in: .whitespacesAndNewlines)
      guard value.contains("rel=\"next\"") else { continue }
      guard let start = value.firstIndex(of: "<"), let end = value.firstIndex(of: ">") else { continue }
      return URL(string: String(value[value.index(after: start) ..< end]))
    }

    return nil
  }
}

struct AnyEncodable: Encodable {
  private let encodeBlock: (Encoder) throws -> Void

  init<T: Encodable>(_ value: T) {
    encodeBlock = value.encode(to:)
  }

  func encode(to encoder: Encoder) throws {
    try encodeBlock(encoder)
  }
}

private extension String {
  var trimmedNonEmpty: String? {
    let value = trimmingCharacters(in: .whitespacesAndNewlines)
    return value.isEmpty ? nil : value
  }
}
