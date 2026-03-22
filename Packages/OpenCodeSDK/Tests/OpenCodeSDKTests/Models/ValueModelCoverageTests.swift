import Foundation
import OpenCodeSDK
import Testing

struct ValueModelCoverageTests {
  @Test func coreModelInitializersAndComputedProperties() {
    let health = HealthResponse(healthy: true, version: "1.0.0")
    #expect(health.healthy == true)
    #expect(health.version == "1.0.0")

    let firstPage = OpenCodePage(items: [1, 2], nextCursor: nil, nextURL: nil)
    #expect(firstPage.items == [1, 2])
    #expect(firstPage.hasNextPage == false)

    let nextPage = OpenCodePage(items: [1], nextCursor: "cursor", nextURL: URL(string: "https://example.com"))
    #expect(nextPage.hasNextPage == true)

    let selector = ModelSelector(providerID: "openai", modelID: "gpt-5")
    #expect(selector.providerID == "openai")
    #expect(selector.modelID == "gpt-5")

    let diff = FileDiff(file: "a.swift", before: "old", after: "new", additions: 1.6, deletions: 2.2, status: "modified")
    #expect(diff.id == "a.swift::old::new")
    #expect(diff.additionsCount == 2)
    #expect(diff.deletionsCount == 2)

    let path = PathInfo(home: "/Users/me", state: "/tmp/state", config: "/tmp/config", worktree: "/tmp/worktree", directory: "/tmp/project")
    #expect(path.directory == "/tmp/project")

    let fileNode = FileNode(name: "README.md", path: "README.md", absolute: "/tmp/project/README.md", type: .file, ignored: false)
    #expect(fileNode.id == "/tmp/project/README.md")
  }

  @Test func sessionAndProjectValueModels() {
    let timestamps = SessionTimestamps(created: 1, updated: 2, archived: 3)
    let session = Session(
      id: "ses_1",
      slug: "slug",
      projectID: "prj_1",
      directory: "/tmp/project",
      parentID: nil,
      title: "Session",
      version: "1",
      time: timestamps,
      summary: .object(["title": .string("summary")]),
      share: .object(["url": .string("https://share")]),
      revert: .object(["messageID": .string("msg_1")])
    )

    #expect(session.sortTimestamp == 2)
    #expect(session.summary?.objectValue?["title"]?.stringValue == "summary")

    let icon = ProjectIcon(url: "https://example.com/icon.png", override: "hammer", color: "blue")
    let commands = ProjectCommands(start: "bun dev")
    let time = ProjectTime(created: 1, updated: 2, initialized: 3)
    let project = ProjectInfo(id: "prj_1", worktree: "/tmp/project", vcs: "git", name: "Project", icon: icon, commands: commands, time: time, sandboxes: ["main"])

    #expect(project.id == "prj_1")
    #expect(project.icon?.override == "hammer")
    #expect(project.commands?.start == "bun dev")
    #expect(project.time.initialized == 3)
  }

  @Test func providerValueModelsAndComputedProperties() {
    let agent = AgentDescriptor(name: "build", description: "Build agent", mode: "primary", hidden: false, native: true, options: ["temperature": .number(0.2)])
    #expect(agent.id == "build")
    #expect(agent.native == true)

    let limit = ProviderModelLimitDescriptor(context: 1000, input: 800, output: 200)
    let model = ProviderModelDescriptor(
      id: "gpt-5",
      providerID: "openai",
      name: "GPT-5",
      family: "gpt",
      status: "active",
      variants: ["fast": .object([:])],
      limit: limit
    )
    let provider = ProviderDescriptor(
      id: "openai",
      name: "OpenAI",
      source: "api",
      env: ["OPENAI_API_KEY"],
      key: "key",
      options: ["region": .string("us")],
      models: ["gpt-5": model]
    )

    let catalog = ProviderCatalogResponse(providers: [provider], defaultModels: ["openai": "gpt-5"])
    #expect(catalog.providers.first?.id == "openai")
    #expect(catalog.defaultModels["openai"] == "gpt-5")

    let list = ProviderListResponse(all: [provider], defaultModels: ["openai": "gpt-5"], connected: ["openai"])
    #expect(list.connected == ["openai"])

    let authMethod = ProviderAuthMethod(type: "api", label: "API key", prompts: [.object(["key": .string("token")])])
    #expect(authMethod.type == "api")

    let modelOption = ModelOption(
      providerID: "openai",
      providerName: "OpenAI",
      modelID: "gpt-5",
      modelName: "GPT-5",
      variants: ["fast", "quality"],
      contextWindow: 1000
    )
    #expect(modelOption.id == "openai::gpt-5")
    #expect(modelOption.selector == ModelSelector(providerID: "openai", modelID: "gpt-5"))
    #expect(modelOption.displayLabel == "GPT-5 (2 variants)")

    let plainOption = ModelOption(
      providerID: "anthropic",
      providerName: "Anthropic",
      modelID: "claude",
      modelName: "Claude",
      variants: [],
      contextWindow: nil
    )
    #expect(plainOption.displayLabel == "Claude")

    let group = ModelProviderGroup(providerID: "openai", providerName: "OpenAI", models: [modelOption])
    #expect(group.id == "openai")
    #expect(group.models.count == 1)
  }

  @Test func fileAndSearchValueModels() throws {
    let hunk = FilePatchHunk(oldStart: 1, oldLines: 2, newStart: 3, newLines: 4, lines: ["-old", "+new"])
    let patch = FilePatch(oldFileName: "old.swift", newFileName: "new.swift", oldHeader: "a", newHeader: "b", hunks: [hunk], index: "123")
    let content = FileContent(type: .text, content: "hello", diff: "@@", patch: patch, encoding: "utf8", mimeType: "text/plain")
    let status = FileStatusEntry(path: "README.md", added: 1, removed: 2, status: .modified)
    let vcs = VCSInfo(branch: "main")

    #expect(content.patch?.oldFileName == "old.swift")
    #expect(status.id == "README.md")
    #expect(vcs.branch == "main")

    let matchText = TextSearchMatchText(text: "needle")
    let submatch = TextSearchSubmatch(match: matchText, start: 4, end: 10)
    let match = TextSearchMatch(
      path: TextSearchPath(text: "Sources/App.swift"),
      lines: TextSearchLines(text: "let needle = 1"),
      lineNumber: 12,
      absoluteOffset: 128,
      submatches: [submatch]
    )
    #expect(match.path.text == "Sources/App.swift")
    #expect(match.submatches.first?.match.text == "needle")

    let symbol = WorkspaceSymbol(
      name: "renderWorkspace",
      kind: 12,
      location: SymbolLocation(
        uri: "file:///tmp/project/Sources/App.swift",
        range: LSPRange(start: LSPPosition(line: 9, character: 2), end: LSPPosition(line: 14, character: 1))
      )
    )
    #expect(symbol.id.contains("renderWorkspace") == true)
    #expect(symbol.location.range.end.character == 1)

    let encoded = try JSONEncoder().encode(match)
    let decoded = try JSONDecoder().decode(TextSearchMatch.self, from: encoded)
    #expect(decoded.lineNumber == 12)
    #expect(decoded.absoluteOffset == 128)
  }

  @Test func skillFormatterAndLSPModels() throws {
    let skill = SkillInfo(name: "swift-concurrency-pro", description: "Concurrency review", location: "/tmp/SKILL.md", content: "Use async await")
    let formatter = FormatterStatus(name: "swiftformat", extensions: ["swift"], enabled: true)

    #expect(skill.id == "swift-concurrency-pro")
    #expect(formatter.id == "swiftformat")

    let connected = LSPServerConnectionState(rawValue: "connected")
    let errored = LSPServerConnectionState(rawValue: "error")
    let unknown = LSPServerConnectionState(rawValue: "mystery")

    #expect(connected.rawValue == "connected")
    #expect(errored.rawValue == "error")
    #expect(unknown.rawValue == "mystery")

    let data = try JSONEncoder().encode(unknown)
    let decoded = try JSONDecoder().decode(LSPServerConnectionState.self, from: data)
    #expect(decoded == .unknown("mystery"))

    let status = LSPServerStatus(id: "sourcekit-lsp", name: "SourceKit-LSP", root: "/tmp/project", status: connected)
    #expect(status.id == "sourcekit-lsp")
    #expect(status.status == .connected)
  }
}
