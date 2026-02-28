import Foundation
import OpenCodeModels

@MainActor
extension WorkspaceStore {
  func seedPreviewWorkspace() {
    let now = Date().timeIntervalSince1970 * 1000
    let previewDirectory = "/tmp/opencode-pocket"
    let previewProject = projects.first(where: { $0.directory == previewDirectory })
      ?? SavedProject(id: "prj_preview_local", name: "opencode-pocket", directory: previewDirectory)
    projects = [previewProject]
    selectedProjectID = previewProject.id
    connection.directory = previewProject.directory

    let primary = Session(
      id: "ses_preview_primary",
      slug: "preview-primary",
      projectID: previewProject.id,
      directory: previewProject.directory,
      parentID: nil,
      title: "Preview Workspace Session",
      version: "1",
      time: SessionTime(created: now - 50000, updated: now - 5000, archived: nil),
      summary: nil,
      share: nil,
      revert: nil
    )

    let secondary = Session(
      id: "ses_preview_secondary",
      slug: "preview-secondary",
      projectID: previewProject.id,
      directory: previewProject.directory,
      parentID: nil,
      title: "Preview Planning Session",
      version: "1",
      time: SessionTime(created: now - 140_000, updated: now - 40000, archived: nil),
      summary: nil,
      share: nil,
      revert: nil
    )

    sessions = [primary, secondary]
    selectedSessionID = primary.id
    sessionStatuses[primary.id] = .idle
    sessionStatuses[secondary.id] = .idle
    diffsBySession[primary.id] = [
      FileDiff(file: "OpenCodePocket/App/AppStore.swift", before: "", after: "", additions: 24, deletions: 9, status: "modified"),
      FileDiff(file: "OpenCodePocket/Features/WorkspaceView.swift", before: "", after: "", additions: 108, deletions: 0, status: "added"),
    ]
    diffsBySession[secondary.id] = []
    todosBySession[primary.id] = [
      TodoItem(content: "Review status output for failing checks", status: "completed", priority: "high"),
      TodoItem(content: "Wire inspector sections into workspace shell", status: "in_progress", priority: "high"),
      TodoItem(content: "Run macOS and iOS validation builds", status: "pending", priority: "medium"),
    ]
    availableAgents = [
      AgentDescriptor(name: "build", description: "Executes tools based on configured permissions.", mode: "primary", hidden: false),
      AgentDescriptor(name: "plan", description: "Planning mode with edit restrictions.", mode: "primary", hidden: false),
    ]
    availableModels = [
      ModelOption(providerID: "openai", providerName: "OpenAI", modelID: "gpt-5.3-codex", modelName: "GPT-5.3 Codex", variants: ["low", "medium", "high"], contextWindow: 272_000),
      ModelOption(providerID: "anthropic", providerName: "Anthropic", modelID: "claude-sonnet-4-5", modelName: "Claude Sonnet 4.5", variants: ["high", "max"], contextWindow: 200_000),
    ]
    let knownKeys = Set(availableModels.map { modelVisibilityKey($0.selector) })
    hiddenModelKeys = hiddenModelKeys.intersection(knownKeys)

    if !availableAgents.contains(where: { $0.name == selectedAgentName }) {
      selectedAgentName = "build"
    }
    reconcileSelectedModel(using: [:])
    reconcileSelectedModelVariant()

    var seededMessages: [MessageEnvelope] = []
    if let greeting = makePreviewMessage(sessionID: primary.id, role: .assistant, text: "Welcome to the preview workspace.") {
      seededMessages.append(greeting)
    }
    if
      let markdownFixture = makePreviewMessage(
        sessionID: primary.id,
        role: .assistant,
        text: previewMarkdownTranscriptFixture,
        providerID: "openai",
        modelID: "gpt-5.3-codex",
        cost: 0.12,
        tokenUsage: MessageTokenUsage(total: 4_321, input: 1_950, output: 1_020, reasoning: 900, cache: .init(read: 300, write: 151))
      )
    {
      seededMessages.append(markdownFixture)
    }
    if !seededMessages.isEmpty {
      messagesBySession[primary.id] = seededMessages
    }

    lspStatuses = [
      LSPServerStatus(id: "sourcekit-lsp", name: "sourcekit-lsp", root: "Packages/OpenCodeSDK", status: .connected),
      LSPServerStatus(id: "yaml-ls", name: "yaml-ls", root: "", status: .error),
    ]
    mcpStatuses = [
      "github": MCPServerStatus(status: .connected),
      "linear": MCPServerStatus(status: .needsAuth),
      "postgres": MCPServerStatus(status: .disabled),
    ]

    connection.isConnected = true
    connection.eventConnectionState = "Preview workspace"
    connection.serverVersion = "preview"
    connection.connectionError = nil
  }

  func makePreviewMessage(
    sessionID: String,
    role: MessageRole,
    text: String,
    providerID: String? = nil,
    modelID: String? = nil,
    cost: Double? = nil,
    tokenUsage: MessageTokenUsage? = nil
  ) -> MessageEnvelope? {
    let messageID = "msg_preview_\(UUID().uuidString.prefix(10))"

    var infoPayload: [String: Any] = [
      "id": messageID,
      "sessionID": sessionID,
      "role": role.rawValue,
      "agent": selectedAgentName,
    ]

    if let providerID {
      infoPayload["providerID"] = providerID
    }

    if let modelID {
      infoPayload["modelID"] = modelID
    }

    if let cost {
      infoPayload["cost"] = cost
    }

    if let tokenUsage {
      var tokensPayload: [String: Any] = [
        "input": tokenUsage.input,
        "output": tokenUsage.output,
        "reasoning": tokenUsage.reasoning,
        "cache": [
          "read": tokenUsage.cache.read,
          "write": tokenUsage.cache.write,
        ],
      ]

      if let total = tokenUsage.total {
        tokensPayload["total"] = total
      }

      infoPayload["tokens"] = tokensPayload
    }

    let payload: [String: Any] = [
      "info": infoPayload,
      "parts": [
        [
          "id": "prt_preview_\(UUID().uuidString.prefix(10))",
          "sessionID": sessionID,
          "messageID": messageID,
          "type": "text",
          "text": text,
        ],
      ],
    ]

    guard
      let data = try? JSONSerialization.data(withJSONObject: payload),
      let envelope = try? JSONDecoder().decode(MessageEnvelope.self, from: data)
    else {
      return nil
    }

    return envelope
  }

  private var previewMarkdownTranscriptFixture: String {
    """
    From our best current science, here is the short version:

    - About 13.8 billion years ago, the universe began in a hot, dense state (the Big Bang).
    - In the first tiny fractions of a second, space expanded extremely fast (inflation), then cooled.
    - Within minutes, the first simple nuclei formed (mostly hydrogen and helium).
    - After about 380,000 years, atoms formed and light could travel freely.
    - Over billions of years, stars and galaxies formed and evolved.

    For details, see [Swift.org](https://swift.org).

    ```swift
    print("hello cosmos")
    ```
    """
  }
}
