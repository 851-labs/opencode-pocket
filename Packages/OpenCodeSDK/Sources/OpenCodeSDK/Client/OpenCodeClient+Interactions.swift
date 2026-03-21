import Foundation

public extension OpenCodeClient {
  func listPermissions(directory: String? = nil) async throws -> [PermissionRequest] {
    try await request(
      .get,
      path: "/permission",
      query: mergedDirectoryQuery(directory),
      response: [PermissionRequest].self
    )
  }

  func replyPermission(
    requestID: String,
    reply: PermissionReply,
    message: String? = nil,
    directory: String? = nil
  ) async throws -> Bool {
    try await respondPermission(requestID: requestID, response: reply, message: message, directory: directory)
  }

  func respondPermission(
    requestID: String,
    response: PermissionReply,
    message: String? = nil,
    directory: String? = nil
  ) async throws -> Bool {
    try await request(
      .post,
      path: "/permission/\(escapedPathComponent(requestID))/reply",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(PermissionReplyRequest(reply: response, message: message)),
      response: Bool.self
    )
  }

  func listQuestions(directory: String? = nil) async throws -> [QuestionRequest] {
    try await request(
      .get,
      path: "/question",
      query: mergedDirectoryQuery(directory),
      response: [QuestionRequest].self
    )
  }

  func replyQuestion(
    requestID: String,
    answers: [QuestionAnswer],
    directory: String? = nil
  ) async throws -> Bool {
    try await request(
      .post,
      path: "/question/\(escapedPathComponent(requestID))/reply",
      query: mergedDirectoryQuery(directory),
      body: AnyEncodable(QuestionReplyRequest(answers: answers)),
      response: Bool.self
    )
  }

  func rejectQuestion(requestID: String, directory: String? = nil) async throws -> Bool {
    try await request(
      .post,
      path: "/question/\(escapedPathComponent(requestID))/reject",
      query: mergedDirectoryQuery(directory),
      response: Bool.self
    )
  }
}
