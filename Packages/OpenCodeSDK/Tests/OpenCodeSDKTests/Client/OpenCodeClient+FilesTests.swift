import Foundation
import OpenCodeSDK
import Testing

@Suite(.tags(.networking))
struct OpenCodeClientFilesTests {
  @Test func fileAndSearchRoutes() async throws {
    let controller = makeSuccessPathController()
    let client = makeClient(controller: controller)

    let listedFiles = try await client.listFiles(path: "", directory: "/tmp/project")
    #expect(listedFiles.count == 2)
    #expect(listedFiles.first?.type == .directory)

    let fileContent = try await client.readFile(path: "README.md", directory: "/tmp/project")
    #expect(fileContent.type == .text)
    #expect(fileContent.mimeType == "text/x-swift")

    let fileStatus = try await client.listFileStatus()
    #expect(fileStatus.first?.path == "README.md")
    #expect(fileStatus.first?.status == .modified)

    let vcs = try await client.getVCSInfo()
    #expect(vcs.branch == "main")

    let directoryMatches = try await client.findFiles(
      query: "src",
      includeDirectories: true,
      type: .directory,
      limit: 10,
      directory: "/tmp/project"
    )
    #expect(directoryMatches == ["src", "tests"])

    let textMatches = try await client.findText(pattern: "value")
    #expect(textMatches.first?.lineNumber == 42)
    #expect(textMatches.first?.submatches.first?.match.text == "value")

    let symbols = try await client.findSymbols(query: "render")
    #expect(symbols.first?.name == "renderWorkspace")
    #expect(symbols.first?.location.range.start.line == 9)

    let requests = controller.recordedRequests
    #expect(requests.contains { $0.url?.path == "/file" && $0.url?.query?.contains("path=") == true })
    #expect(requests.contains { $0.url?.path == "/file/content" && $0.url?.query?.contains("path=README.md") == true })
    #expect(requests.contains { $0.url?.path == "/file/status" && $0.httpMethod == "GET" })
    #expect(requests.contains { $0.url?.path == "/find/file" && $0.url?.query?.contains("type=directory") == true })
    #expect(requests.contains { $0.url?.path == "/find/file" && $0.url?.query?.contains("dirs=true") == true })
    #expect(requests.contains { $0.url?.path == "/find/file" && $0.url?.query?.contains("limit=10") == true })
    #expect(requests.contains { $0.url?.path == "/find" && $0.url?.query?.contains("pattern=value") == true })
    #expect(requests.contains { $0.url?.path == "/find/symbol" && $0.url?.query?.contains("query=render") == true })
    #expect(requests.contains { $0.url?.path == "/vcs" && $0.httpMethod == "GET" })
  }

  @Test func listMessagesPageIgnoresMalformedNextLink() async throws {
    let controller = URLProtocolStubController { request in
      try makeStatusResponse(
        request: request,
        code: 200,
        body: Data(("[" + sampleMessageJSON(id: "msg_list", sessionID: "ses_1", text: "listed") + "]").utf8),
        headers: [
          "Content-Type": "application/json",
          "Link": "not-a-link; rel=\"next\"",
          "X-Next-Cursor": "cur_5",
        ]
      )
    }

    let client = makeClient(controller: controller)
    let page = try await client.listMessagesPage(sessionID: "ses_1", limit: 5)

    #expect(page.nextCursor == "cur_5")
    #expect(page.nextURL == nil)
  }
}
