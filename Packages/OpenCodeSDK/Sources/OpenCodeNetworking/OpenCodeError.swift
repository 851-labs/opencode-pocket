import Foundation
import OpenCodeModels

public enum OpenCodeClientError: LocalizedError {
  case invalidURL(String)
  case invalidResponse
  case transport(Error)
  case decoding(Error)
  case httpStatus(code: Int, message: String?)
  case message(String)

  public var errorDescription: String? {
    switch self {
    case let .invalidURL(value):
      return "Invalid server URL: \(value)"
    case .invalidResponse:
      return "Server returned an invalid response."
    case let .transport(error):
      return "Network error: \(error.localizedDescription)"
    case let .decoding(error):
      return "Failed to decode server response: \(error.localizedDescription)"
    case let .httpStatus(code, message):
      return "Server error (\(code)): \(message ?? "No details")"
    case let .message(message):
      return message
    }
  }
}

struct APIBadRequestEnvelope: Decodable {
  let data: JSONValue?
  let errors: [JSONValue]?
  let success: Bool?
}

struct APINotFoundEnvelope: Decodable {
  struct DataEnvelope: Decodable {
    let message: String?
  }

  let name: String
  let data: DataEnvelope
}
