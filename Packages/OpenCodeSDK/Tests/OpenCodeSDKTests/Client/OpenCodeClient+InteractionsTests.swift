import Foundation
import OpenCodeSDK
import Testing

struct OpenCodeClientInteractionsTests {
  @Test func interactionRoutes() async throws {
    let controller = makeSuccessPathController()
    let client = makeClient(controller: controller)

    let permissions = try await client.listPermissions()
    #expect(permissions.first?.id == "perm_1")

    let repliedPermission = try await client.respondPermission(requestID: "perm_1", response: .once, message: "Proceed")
    #expect(repliedPermission == true)

    let questions = try await client.listQuestions()
    #expect(questions.first?.id == "question_1")

    let repliedQuestion = try await client.replyQuestion(requestID: "question_1", answers: [["Yes"]])
    #expect(repliedQuestion == true)

    let rejectedQuestion = try await client.rejectQuestion(requestID: "question_1")
    #expect(rejectedQuestion == true)

    let requests = controller.recordedRequests
    #expect(requests.contains { $0.url?.path == "/permission" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/permission/perm_1/reply" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/question" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/question/question_1/reply" && $0.httpMethod == "POST" })
    #expect(requests.contains { $0.url?.path == "/question/question_1/reject" && $0.httpMethod == "POST" })
  }
}
