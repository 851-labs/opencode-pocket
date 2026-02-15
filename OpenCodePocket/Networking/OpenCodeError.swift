import Foundation

enum OpenCodeClientError: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case transport(Error)
    case decoding(Error)
    case httpStatus(code: Int, message: String?)
    case message(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let value):
            return "Invalid server URL: \(value)"
        case .invalidResponse:
            return "Server returned an invalid response."
        case .transport(let error):
            return "Network error: \(error.localizedDescription)"
        case .decoding(let error):
            return "Failed to decode server response: \(error.localizedDescription)"
        case .httpStatus(let code, let message):
            return "Server error (\(code)): \(message ?? "No details")"
        case .message(let message):
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
