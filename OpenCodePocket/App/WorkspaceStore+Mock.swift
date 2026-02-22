import Foundation
import OpenCodeModels

@MainActor
extension WorkspaceStore {
  func seedMockWorkspace() {
    let now = Date().timeIntervalSince1970 * 1000
    let mockDirectory = "/tmp/opencode-pocket"
    let mockProject = projects.first(where: { $0.directory == mockDirectory })
      ?? SavedProject(id: "prj_mock_local", name: "opencode-pocket", directory: mockDirectory)
    projects = [mockProject]
    selectedProjectID = mockProject.id
    connection.directory = mockProject.directory

    let primary = Session(
      id: "ses_mock_primary",
      slug: "mock-primary",
      projectID: mockProject.id,
      directory: mockProject.directory,
      parentID: nil,
      title: "Mock Workspace Session",
      version: "1",
      time: SessionTime(created: now - 50000, updated: now - 5000, archived: nil),
      summary: nil,
      share: nil,
      revert: nil
    )

    let secondary = Session(
      id: "ses_mock_secondary",
      slug: "mock-secondary",
      projectID: mockProject.id,
      directory: mockProject.directory,
      parentID: nil,
      title: "Mock Planning Session",
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
    availableAgents = [
      AgentDescriptor(name: "build", description: "Executes tools based on configured permissions.", mode: "primary", hidden: false),
      AgentDescriptor(name: "plan", description: "Planning mode with edit restrictions.", mode: "primary", hidden: false),
    ]
    availableModels = [
      ModelOption(providerID: "openai", providerName: "OpenAI", modelID: "gpt-5.3-codex", modelName: "GPT-5.3 Codex", variants: ["low", "medium", "high"]),
      ModelOption(providerID: "anthropic", providerName: "Anthropic", modelID: "claude-sonnet-4-5", modelName: "Claude Sonnet 4.5", variants: ["high", "max"]),
    ]
    let knownKeys = Set(availableModels.map { modelVisibilityKey($0.selector) })
    hiddenModelKeys = hiddenModelKeys.intersection(knownKeys)

    if !availableAgents.contains(where: { $0.name == selectedAgentName }) {
      selectedAgentName = "build"
    }
    reconcileSelectedModel(using: [:])
    reconcileSelectedModelVariant()

    var seededMessages: [MessageEnvelope] = []
    if let greeting = makeMockMessage(sessionID: primary.id, role: .assistant, text: "Welcome to the mock workspace.") {
      seededMessages.append(greeting)
    }
    if let markdownFixture = makeMockMessage(sessionID: primary.id, role: .assistant, text: mockMarkdownTranscriptFixture) {
      seededMessages.append(markdownFixture)
    }
    if !seededMessages.isEmpty {
      messagesBySession[primary.id] = seededMessages
    }

    connection.isConnected = true
    connection.eventConnectionState = "Mock workspace"
    connection.serverVersion = "mock"
    connection.connectionError = nil
  }

  func makeMockMessage(sessionID: String, role: MessageRole, text: String) -> MessageEnvelope? {
    let messageID = "msg_mock_\(UUID().uuidString.prefix(10))"

    let payload: [String: Any] = [
      "info": [
        "id": messageID,
        "sessionID": sessionID,
        "role": role.rawValue,
        "agent": selectedAgentName,
      ],
      "parts": [
        [
          "id": "prt_mock_\(UUID().uuidString.prefix(10))",
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

  private var mockMarkdownTranscriptFixture: String {
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
