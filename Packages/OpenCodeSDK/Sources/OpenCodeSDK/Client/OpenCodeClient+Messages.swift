import Foundation

public extension OpenCodeClient {
  func listMessages(
    sessionID: String,
    limit: Int? = nil,
    before: String? = nil,
    directory: String? = nil
  ) async throws -> [MessageEnvelope] {
    let page = try await listMessagesPage(sessionID: sessionID, limit: limit, before: before, directory: directory)
    return page.items
  }

  func listMessagesPage(
    sessionID: String,
    limit: Int? = nil,
    before: String? = nil,
    directory: String? = nil
  ) async throws -> OpenCodePage<MessageEnvelope> {
    var query = mergedDirectoryQuery(directory)
    if let limit {
      query.append(URLQueryItem(name: "limit", value: String(limit)))
    }

    if let before, !before.isEmpty {
      query.append(URLQueryItem(name: "before", value: before))
    }

    return try await requestPage(
      .get,
      path: "/session/\(escapedPathComponent(sessionID))/message",
      query: query,
      response: MessageEnvelope.self
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

  func deleteMessage(sessionID: String, messageID: String, directory: String? = nil) async throws -> Bool {
    try await request(
      .delete,
      path: "/session/\(escapedPathComponent(sessionID))/message/\(escapedPathComponent(messageID))",
      query: mergedDirectoryQuery(directory),
      response: Bool.self
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

  func sendSessionCommand(
    sessionID: String,
    body: SessionCommandRequest,
    directory: String? = nil
  ) async throws -> MessageEnvelope {
    try await request(
      .post,
      path: "/session/\(escapedPathComponent(sessionID))/command",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(body),
      response: MessageEnvelope.self
    )
  }

  func sendSessionShell(
    sessionID: String,
    body: SessionShellRequest,
    directory: String? = nil
  ) async throws -> MessageEnvelope {
    try await request(
      .post,
      path: "/session/\(escapedPathComponent(sessionID))/shell",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(body),
      response: MessageEnvelope.self
    )
  }

  func deletePart(sessionID: String, messageID: String, partID: String, directory: String? = nil) async throws -> Bool {
    try await request(
      .delete,
      path: "/session/\(escapedPathComponent(sessionID))/message/\(escapedPathComponent(messageID))/part/\(escapedPathComponent(partID))",
      query: mergedDirectoryQuery(directory),
      response: Bool.self
    )
  }

  func updatePart(
    sessionID: String,
    messageID: String,
    partID: String,
    part: MessagePart,
    directory: String? = nil
  ) async throws -> MessagePart {
    try await request(
      .patch,
      path: "/session/\(escapedPathComponent(sessionID))/message/\(escapedPathComponent(messageID))/part/\(escapedPathComponent(partID))",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(part),
      response: MessagePart.self
    )
  }
}
