import Foundation

struct OpenCodeClientConfiguration: Sendable {
    let baseURL: URL
    let username: String?
    let password: String?
    let directory: String?
}

final class OpenCodeClient {
    private let configuration: OpenCodeClientConfiguration
    private let requestBuilder: HTTPRequestBuilder
    private let urlSession: URLSession

    init(configuration: OpenCodeClientConfiguration, urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.requestBuilder = HTTPRequestBuilder(
            baseURL: configuration.baseURL,
            username: configuration.username,
            password: configuration.password
        )
        self.urlSession = urlSession
    }

    func health() async throws -> HealthResponse {
        try await request(.get, path: "/global/health", response: HealthResponse.self)
    }

    func listSessions(directory: String? = nil) async throws -> [Session] {
        try await request(.get, path: "/session", query: mergedDirectoryQuery(directory), response: [Session].self)
    }

    func createSession(_ body: SessionCreateRequest, directory: String? = nil) async throws -> Session {
        try await request(
            .post,
            path: "/session",
            query: mergedDirectoryQuery(directory),
            body: AnyEncodable(body),
            response: Session.self
        )
    }

    func getSession(id: String, directory: String? = nil) async throws -> Session {
        try await request(
            .get,
            path: "/session/\(escapedPathComponent(id))",
            query: mergedDirectoryQuery(directory),
            response: Session.self
        )
    }

    func updateSession(id: String, body: SessionUpdateRequest, directory: String? = nil) async throws -> Session {
        try await request(
            .patch,
            path: "/session/\(escapedPathComponent(id))",
            query: mergedDirectoryQuery(directory),
            body: AnyEncodable(body),
            response: Session.self
        )
    }

    func deleteSession(id: String, directory: String? = nil) async throws -> Bool {
        try await request(
            .delete,
            path: "/session/\(escapedPathComponent(id))",
            query: mergedDirectoryQuery(directory),
            response: Bool.self
        )
    }

    func listMessages(sessionID: String, limit: Int? = nil, directory: String? = nil) async throws -> [MessageEnvelope] {
        var query = mergedDirectoryQuery(directory)
        if let limit {
            query.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        return try await request(
            .get,
            path: "/session/\(escapedPathComponent(sessionID))/message",
            query: query,
            response: [MessageEnvelope].self
        )
    }

    func getMessage(sessionID: String, messageID: String, directory: String? = nil) async throws -> MessageEnvelope {
        try await request(
            .get,
            path: "/session/\(escapedPathComponent(sessionID))/message/\(escapedPathComponent(messageID))",
            query: mergedDirectoryQuery(directory),
            response: MessageEnvelope.self
        )
    }

    func sendMessage(sessionID: String, body: PromptRequest, directory: String? = nil) async throws -> MessageEnvelope {
        try await request(
            .post,
            path: "/session/\(escapedPathComponent(sessionID))/message",
            query: mergedDirectoryQuery(directory),
            body: AnyEncodable(body),
            response: MessageEnvelope.self
        )
    }

    func sendMessageAsync(sessionID: String, body: PromptRequest, directory: String? = nil) async throws {
        try await requestNoContent(
            .post,
            path: "/session/\(escapedPathComponent(sessionID))/prompt_async",
            query: mergedDirectoryQuery(directory),
            body: AnyEncodable(body)
        )
    }

    func abortSession(sessionID: String, directory: String? = nil) async throws -> Bool {
        try await request(
            .post,
            path: "/session/\(escapedPathComponent(sessionID))/abort",
            query: mergedDirectoryQuery(directory),
            response: Bool.self
        )
    }

    func subscribeEvents(directory: String? = nil) -> AsyncStream<ServerEvent> {
        AsyncStream { continuation in
            let task = Task {
                var attempts = 0

                while !Task.isCancelled {
                    do {
                        let request = try requestBuilder.makeRequest(
                            path: "/event",
                            method: .get,
                            query: mergedDirectoryQuery(directory),
                            timeout: 600
                        )

                        let (bytes, response) = try await urlSession.bytes(for: request)
                        guard let httpResponse = response as? HTTPURLResponse else {
                            throw OpenCodeClientError.invalidResponse
                        }
                        guard (200..<300).contains(httpResponse.statusCode) else {
                            throw OpenCodeClientError.httpStatus(code: httpResponse.statusCode, message: "Unable to subscribe to event stream")
                        }

                        attempts = 0
                        var parser = SSEParser()

                        for try await line in bytes.lines {
                            if Task.isCancelled { break }
                            if let message = parser.ingest(line: line), let data = message.data {
                                yieldEvent(from: data, to: continuation)
                            }
                        }

                        if let message = parser.finish(), let data = message.data {
                            yieldEvent(from: data, to: continuation)
                        }
                    } catch {
                        if Task.isCancelled {
                            break
                        }

                        attempts += 1
                        let delay = min(pow(2.0, Double(max(0, attempts - 1))), 15.0)
                        let nanoseconds = UInt64(delay * 1_000_000_000)
                        try? await Task.sleep(nanoseconds: nanoseconds)
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func request<T: Decodable>(
        _ method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        body: AnyEncodable? = nil,
        response type: T.Type
    ) async throws -> T {
        let bodyData = try encodeBody(body)
        let request = try requestBuilder.makeRequest(path: path, method: method, query: query, body: bodyData)

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = try validatedHTTPResponse(from: response)

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw parseHTTPError(code: httpResponse.statusCode, data: data)
            }

            do {
                return try JSONDecoder().decode(type, from: data)
            } catch {
                throw OpenCodeClientError.decoding(error)
            }
        } catch let error as OpenCodeClientError {
            throw error
        } catch {
            throw OpenCodeClientError.transport(error)
        }
    }

    private func requestNoContent(
        _ method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        body: AnyEncodable? = nil
    ) async throws {
        let bodyData = try encodeBody(body)
        let request = try requestBuilder.makeRequest(path: path, method: method, query: query, body: bodyData)

        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = try validatedHTTPResponse(from: response)

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw parseHTTPError(code: httpResponse.statusCode, data: data)
            }
        } catch let error as OpenCodeClientError {
            throw error
        } catch {
            throw OpenCodeClientError.transport(error)
        }
    }

    private func validatedHTTPResponse(from response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenCodeClientError.invalidResponse
        }
        return httpResponse
    }

    private func encodeBody(_ body: AnyEncodable?) throws -> Data? {
        guard let body else { return nil }
        do {
            return try JSONEncoder().encode(body)
        } catch {
            throw OpenCodeClientError.message("Failed to encode request body: \(error.localizedDescription)")
        }
    }

    private func parseHTTPError(code: Int, data: Data) -> OpenCodeClientError {
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

    private func escapedPathComponent(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
    }

    private func mergedDirectoryQuery(_ override: String?) -> [URLQueryItem] {
        let resolved = (override?.trimmedNonEmpty) ?? configuration.directory?.trimmedNonEmpty
        guard let resolved else {
            return []
        }
        return [URLQueryItem(name: "directory", value: resolved)]
    }

    private func yieldEvent(from data: String, to continuation: AsyncStream<ServerEvent>.Continuation) {
        let payload = data.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !payload.isEmpty else { return }

        if let event = try? JSONDecoder().decode(ServerEvent.self, from: Data(payload.utf8)) {
            continuation.yield(event)
            return
        }

        continuation.yield(
            ServerEvent(
                type: "event.decode.error",
                properties: .object([
                    "raw": .string(payload)
                ])
            )
        )
    }
}

private struct AnyEncodable: Encodable {
    private let encodeBlock: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        self.encodeBlock = value.encode(to:)
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
