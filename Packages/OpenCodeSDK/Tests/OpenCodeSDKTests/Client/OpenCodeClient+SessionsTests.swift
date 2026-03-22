import Foundation
import OpenCodeSDK
import Testing

@Suite(.tags(.networking))
struct OpenCodeClientSessionsTests {
  @Test func sessionRoutes() async throws {
    let controller = makeSuccessPathController()
    let client = makeClient(controller: controller)

    let sessions = try await client.listSessions(roots: true, limit: 10)
    #expect(sessions.count == 1)

    let sessionChildren = try await client.listSessionChildren(sessionID: "ses_1")
    #expect(sessionChildren.first?.parentID == "ses_1")

    let sessionStatuses = try await client.listSessionStatuses()
    #expect(sessionStatuses["ses_1"]?.type == .busy)
    #expect(sessionStatuses["ses_2"]?.type == .retry)

    let created = try await client.createSession(SessionCreateRequest(title: "Hi"))
    #expect(created.id == "ses_new")

    let fetched = try await client.getSession(id: "ses 1")
    #expect(fetched.id == "ses_get")

    let initialized = try await client.initializeSession(
      sessionID: "ses_1",
      body: SessionInitializeRequest(providerID: "openai", modelID: "gpt-5", messageID: "msg_1")
    )
    #expect(initialized == true)

    let forked = try await client.forkSession(sessionID: "ses_1", body: SessionForkRequest(messageID: "msg_1"))
    #expect(forked.id == "ses_fork")

    let updated = try await client.updateSession(id: "ses 1", body: SessionUpdateRequest(title: "Renamed"))
    #expect(updated.id == "ses_patch")

    let deleted = try await client.deleteSession(id: "ses_1")
    #expect(deleted == true)

    let diffs = try await client.getSessionDiff(sessionID: "ses_1", messageID: "msg_1")
    #expect(diffs.first?.file == "a.swift")

    let todos = try await client.getSessionTodo(sessionID: "ses_1")
    #expect(todos.first?.content == "Implement API")

    let aborted = try await client.abortSession(sessionID: "ses_1")
    #expect(aborted == true)

    let reverted = try await client.revertSession(sessionID: "ses_1", body: SessionRevertRequest(messageID: "msg_1"))
    #expect(reverted.id == "ses_revert")
    #expect(reverted.revert?.objectValue?["messageID"]?.stringValue == "msg_1")

    let unreverted = try await client.unrevertSession(sessionID: "ses_1")
    #expect(unreverted.revert == nil)

    let summarized = try await client.summarizeSession(
      sessionID: "ses_1",
      body: SessionSummarizeRequest(providerID: "openai", modelID: "gpt-5")
    )
    #expect(summarized == true)

    let shared = try await client.shareSession(sessionID: "ses_1")
    #expect(shared.share?.objectValue?["url"]?.stringValue == "https://share/opencode")

    let unshared = try await client.unshareSession(sessionID: "ses_1")
    #expect(unshared.share == nil)

    let requests = controller.recordedRequests
    #expect(requests.contains { $0.url?.path == "/session" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/session" && $0.url?.query?.contains("directory=/tmp/default") == true })
    #expect(requests.contains { $0.url?.path == "/session" && $0.url?.query?.contains("roots=true") == true })
    #expect(requests.contains { $0.url?.path == "/session" && $0.url?.query?.contains("limit=10") == true })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/children" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/session/status" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/init" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/fork" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/abort" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/share" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/share" && $0.httpMethod == "DELETE" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/revert" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/unrevert" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/summarize" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/session/ses_1/todo" && $0.httpMethod == "GET" })
  }
}
