import Foundation

public extension OpenCodeClient {
  func listSessions(
    directory: String? = nil,
    roots: Bool? = nil,
    start: Double? = nil,
    search: String? = nil,
    limit: Int? = nil
  ) async throws -> [Session] {
    var query = mergedDirectoryQuery(directory)
    if let roots {
      query.append(URLQueryItem(name: "roots", value: roots ? "true" : "false"))
    }
    if let start {
      query.append(URLQueryItem(name: "start", value: String(start)))
    }
    if let search, !search.isEmpty {
      query.append(URLQueryItem(name: "search", value: search))
    }
    if let limit {
      query.append(URLQueryItem(name: "limit", value: String(limit)))
    }

    return try await request(.get, path: "/session", query: query, response: [Session].self)
  }

  func listSessionChildren(sessionID: String, directory: String? = nil) async throws -> [Session] {
    try await request(
      .get,
      path: "/session/\(escapedPathComponent(sessionID))/children",
      query: mergedDirectoryQuery(directory),
      response: [Session].self
    )
  }

  func listSessionStatuses() async throws -> [String: SessionStatus] {
    try await request(.get, path: "/session/status", response: [String: SessionStatus].self)
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

  func initializeSession(
    sessionID: String,
    body: SessionInitializeRequest,
    directory: String? = nil
  ) async throws -> Bool {
    try await request(
      .post,
      path: "/session/\(escapedPathComponent(sessionID))/init",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(body),
      response: Bool.self
    )
  }

  func forkSession(
    sessionID: String,
    body: SessionForkRequest = SessionForkRequest(),
    directory: String? = nil
  ) async throws -> Session {
    try await request(
      .post,
      path: "/session/\(escapedPathComponent(sessionID))/fork",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(body),
      response: Session.self
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

  func revertSession(
    sessionID: String,
    body: SessionRevertRequest,
    directory: String? = nil
  ) async throws -> Session {
    try await request(
      .post,
      path: "/session/\(escapedPathComponent(sessionID))/revert",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(body),
      response: Session.self
    )
  }

  func unrevertSession(sessionID: String, directory: String? = nil) async throws -> Session {
    try await request(
      .post,
      path: "/session/\(escapedPathComponent(sessionID))/unrevert",
      query: mergedDirectoryQuery(directory),
      response: Session.self
    )
  }

  func summarizeSession(
    sessionID: String,
    body: SessionSummarizeRequest,
    directory: String? = nil
  ) async throws -> Bool {
    try await request(
      .post,
      path: "/session/\(escapedPathComponent(sessionID))/summarize",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(body),
      response: Bool.self
    )
  }

  func shareSession(sessionID: String, directory: String? = nil) async throws -> Session {
    try await request(
      .post,
      path: "/session/\(escapedPathComponent(sessionID))/share",
      query: mergedDirectoryQuery(directory),
      response: Session.self
    )
  }

  func unshareSession(sessionID: String, directory: String? = nil) async throws -> Session {
    try await request(
      .delete,
      path: "/session/\(escapedPathComponent(sessionID))/share",
      query: mergedDirectoryQuery(directory),
      response: Session.self
    )
  }

  func getSessionDiff(sessionID: String, messageID: String? = nil, directory: String? = nil) async throws -> [FileDiff] {
    var query = mergedDirectoryQuery(directory)
    if let messageID {
      query.append(URLQueryItem(name: "messageID", value: messageID))
    }

    return try await request(
      .get,
      path: "/session/\(escapedPathComponent(sessionID))/diff",
      query: query,
      response: [FileDiff].self
    )
  }

  func getSessionTodo(sessionID: String, directory: String? = nil) async throws -> [TodoItem] {
    try await request(
      .get,
      path: "/session/\(escapedPathComponent(sessionID))/todo",
      query: mergedDirectoryQuery(directory),
      response: [TodoItem].self
    )
  }
}
