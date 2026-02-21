#if os(macOS)
import OpenCodeModels
import SwiftUI

private enum MacWorkspacePanel: String, CaseIterable, Identifiable {
  case transcript = "Transcript"
  case changes = "Changes"

  var id: Self { self }
}

struct MacWorkspaceView: View {
  @Bindable var store: WorkspaceStore

  @State private var selectedPanel: MacWorkspacePanel = .transcript
  @State private var isRenameSheetPresented = false
  @State private var isDeleteConfirmationPresented = false
  @State private var renameDraft = ""

  private var selectedSessionID: String? {
    store.selectedSessionID
  }

  var body: some View {
    NavigationSplitView {
      sidebar
    } detail: {
      detail
    }
    .navigationSplitViewStyle(.balanced)
    .task {
      await store.refreshAgentAndModelOptions()
      await store.refreshSessions()
    }
    .onChange(of: store.selectedSessionID) { _, newValue in
      Task {
        await store.selectSession(newValue)
      }
    }
    .sheet(isPresented: $isRenameSheetPresented) {
      renameSheet
    }
    .confirmationDialog("Delete Session?", isPresented: $isDeleteConfirmationPresented) {
      Button("Delete", role: .destructive) {
        deleteSelectedSession()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This permanently removes the selected chat session.")
    }
    .toolbar {
      toolbarContent
    }
  }

  private var sidebar: some View {
    List(selection: $store.selectedSessionID) {
      ForEach(store.visibleSessions) { session in
        VStack(alignment: .leading, spacing: 4) {
          Text(session.title)
            .font(.body.weight(.semibold))
            .lineLimit(1)

          HStack(spacing: 6) {
            Text(session.id)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)

            Circle()
              .fill(.secondary.opacity(0.5))
              .frame(width: 3, height: 3)

            Text(store.statusLabel(for: session.id))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .tag(session.id as String?)
      }
    }
    .navigationTitle("Sessions")
    .overlay {
      if store.visibleSessions.isEmpty {
        ContentUnavailableView(
          "No Sessions",
          systemImage: "tray",
          description: Text("Create a session to start chatting with your OpenCode server.")
        )
      }
    }
  }

  @ViewBuilder
  private var detail: some View {
    if let selectedSessionID {
      VStack(spacing: 0) {
        HStack(spacing: 12) {
          Text(store.sessionTitle(for: selectedSessionID))
            .font(.title3.weight(.semibold))
            .lineLimit(1)

          Spacer(minLength: 0)

          Picker("Panel", selection: $selectedPanel) {
            ForEach(MacWorkspacePanel.allCases) { panel in
              Text(panel.rawValue).tag(panel)
            }
          }
          .pickerStyle(.segmented)
          .frame(width: 220)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)

        Divider()

        Group {
          switch selectedPanel {
          case .transcript:
            MacTranscriptPane(
              messages: store.messagesBySession[selectedSessionID] ?? [],
              sessionStatus: store.status(for: selectedSessionID)
            )
          case .changes:
            MacChangesPane(diffs: store.diffsBySession[selectedSessionID] ?? [])
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        Divider()

        MacComposerView(store: store, sessionID: selectedSessionID)
          .padding(12)
      }
    } else {
      ContentUnavailableView(
        "No Session Selected",
        systemImage: "bubble.left.and.bubble.right",
        description: Text("Select or create a session from the sidebar.")
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItemGroup {
      Button {
        Task {
          await store.refreshSessions()
        }
      } label: {
        if store.isRefreshingSessions {
          ProgressView()
            .controlSize(.small)
        } else {
          Image(systemName: "arrow.clockwise")
        }
      }
      .disabled(store.isRefreshingSessions)
      .accessibilityIdentifier("sessions.refresh")

      Button {
        Task {
          await store.createSession()
        }
      } label: {
        if store.isCreatingSession {
          ProgressView()
            .controlSize(.small)
        } else {
          Image(systemName: "plus")
        }
      }
      .disabled(store.isCreatingSession)
      .accessibilityIdentifier("sessions.create")
    }

    ToolbarItem {
      Button("Disconnect") {
        store.disconnect()
      }
      .accessibilityIdentifier("sessions.disconnect")
    }

    ToolbarItem(placement: .primaryAction) {
      Menu {
        Button("Rename") {
          prepareRenameSession()
        }
        .disabled(selectedSessionID == nil)

        Button("Archive") {
          archiveSelectedSession()
        }
        .disabled(selectedSessionID == nil)

        Button("Delete", role: .destructive) {
          isDeleteConfirmationPresented = true
        }
        .disabled(selectedSessionID == nil)
      } label: {
        Label("Session Actions", systemImage: "ellipsis.circle")
      }
      .accessibilityIdentifier("workspace.actions.menu")
    }
  }

  private var renameSheet: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Rename Session")
        .font(.headline)

      TextField("Session title", text: $renameDraft)

      HStack {
        Spacer()

        Button("Cancel") {
          isRenameSheetPresented = false
        }

        Button("Save") {
          saveRename()
          isRenameSheetPresented = false
        }
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(18)
    .frame(width: 360)
  }

  private func prepareRenameSession() {
    guard let selectedSessionID else { return }
    renameDraft = store.sessionTitle(for: selectedSessionID)
    isRenameSheetPresented = true
  }

  private func archiveSelectedSession() {
    guard let selectedSessionID else { return }
    Task {
      await store.archiveSession(sessionID: selectedSessionID)
    }
  }

  private func deleteSelectedSession() {
    guard let selectedSessionID else { return }
    Task {
      await store.deleteSession(sessionID: selectedSessionID)
    }
  }

  private func saveRename() {
    guard let selectedSessionID else { return }
    Task {
      await store.renameSession(sessionID: selectedSessionID, title: renameDraft)
    }
  }
}

private struct MacTranscriptPane: View {
  let messages: [MessageEnvelope]
  let sessionStatus: SessionStatus

  private var turns: [MacTranscriptTurn] {
    MacTranscriptTurn.build(from: messages)
  }

  var body: some View {
    if turns.isEmpty {
      ContentUnavailableView(
        "No Messages Yet",
        systemImage: "text.bubble",
        description: Text("Send a message to start this session.")
      )
    } else {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 12) {
          ForEach(Array(turns.enumerated()), id: \.element.id) { index, turn in
            MacTurnView(
              turn: turn,
              isWorking: index == turns.count - 1 && sessionStatus.isRunning
            )
          }
        }
        .padding(16)
      }
    }
  }
}

private struct MacTranscriptTurn: Identifiable {
  let id: String
  let user: MessageEnvelope?
  let assistantMessages: [MessageEnvelope]

  static func build(from messages: [MessageEnvelope]) -> [MacTranscriptTurn] {
    var turns: [MacTranscriptTurn] = []
    var index = 0

    while index < messages.count {
      let current = messages[index]

      if current.info.role == .user {
        var assistants: [MessageEnvelope] = []
        var scan = index + 1

        while scan < messages.count {
          let next = messages[scan]
          if next.info.role == .user {
            break
          }

          if next.info.role == .assistant {
            if let parentID = next.info.parentID {
              if parentID == current.id {
                assistants.append(next)
              }
            } else {
              assistants.append(next)
            }
          }

          scan += 1
        }

        turns.append(MacTranscriptTurn(id: current.id, user: current, assistantMessages: assistants))
        index = scan
        continue
      }

      if current.info.role == .assistant {
        turns.append(MacTranscriptTurn(id: current.id, user: nil, assistantMessages: [current]))
      }

      index += 1
    }

    return turns
  }
}

private struct MacTurnView: View {
  let turn: MacTranscriptTurn
  let isWorking: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let user = turn.user {
        MacUserMessageCard(message: user)
      }

      ForEach(turn.assistantMessages) { assistant in
        MacAssistantMessageCard(message: assistant)
      }

      if isWorking {
        HStack(spacing: 8) {
          ProgressView()
            .controlSize(.small)
          Text("Thinking...")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.leading, 8)
      }

      if
        let user = turn.user,
        !user.info.summaryDiffs.isEmpty,
        !isWorking
      {
        MacTurnDiffSummaryCard(diffs: user.info.summaryDiffs)
      }
    }
  }
}

private struct MacUserMessageCard: View {
  let message: MessageEnvelope

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("You")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      MacMarkdownText(text: message.textBody)
        .font(.body)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .trailing)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.accentColor.opacity(0.16))
    )
  }
}

private struct MacAssistantMessageCard: View {
  let message: MessageEnvelope

  private var groupedParts: [MacAssistantItem] {
    let visibleParts = message.parts.filter { part in
      !(part.type == "tool" && (part.tool == "todowrite" || part.tool == "todoread"))
    }

    var result: [MacAssistantItem] = []
    var contextBuffer: [MessagePart] = []

    for part in visibleParts {
      if part.isContextTool {
        contextBuffer.append(part)
        continue
      }

      if !contextBuffer.isEmpty {
        result.append(.context(id: contextBuffer[0].id, tools: contextBuffer))
        contextBuffer.removeAll(keepingCapacity: true)
      }

      result.append(.part(part))
    }

    if !contextBuffer.isEmpty {
      result.append(.context(id: contextBuffer[0].id, tools: contextBuffer))
    }

    return result
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Assistant")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      if groupedParts.isEmpty {
        Text("(Assistant response has no visible parts yet)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      ForEach(groupedParts) { item in
        switch item {
        case let .part(part):
          MacAssistantPartView(part: part)
        case let .context(_, tools):
          MacContextToolGroupCard(parts: tools)
        }
      }

      if let errorText = message.info.errorDisplayText {
        Text(errorText)
          .font(.caption)
          .foregroundStyle(.red)
          .padding(8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(Color.red.opacity(0.08))
          )
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.gray.opacity(0.12))
    )
  }
}

private enum MacAssistantItem: Identifiable {
  case part(MessagePart)
  case context(id: String, tools: [MessagePart])

  var id: String {
    switch self {
    case let .part(part):
      return part.id
    case let .context(id, _):
      return "ctx::\(id)"
    }
  }
}

private struct MacAssistantPartView: View {
  let part: MessagePart

  var body: some View {
    switch part.type {
    case "text":
      if let text = part.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
        MacMarkdownText(text: text)
          .font(.body)
      }
    case "reasoning":
      if let text = part.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
        DisclosureGroup("Reasoning") {
          MacMarkdownText(text: text)
            .font(.subheadline)
            .padding(.top, 6)
        }
      }
    case "tool":
      MacToolPartCard(part: part)
    default:
      if let rendered = part.renderedText {
        Text(rendered)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct MacContextToolGroupCard: View {
  let parts: [MessagePart]
  @State private var isExpanded = false

  private var summary: String {
    let reads = parts.filter { $0.tool == "read" }.count
    let searches = parts.filter { $0.tool == "glob" || $0.tool == "grep" }.count
    let lists = parts.filter { $0.tool == "list" }.count

    let chunks = [
      reads > 0 ? "\(reads) read\(reads == 1 ? "" : "s")" : nil,
      searches > 0 ? "\(searches) search\(searches == 1 ? "" : "es")" : nil,
      lists > 0 ? "\(lists) list\(lists == 1 ? "" : "s")" : nil,
    ]
      .compactMap { $0 }

    return chunks.joined(separator: ", ")
  }

  private var hasPendingWork: Bool {
    parts.contains { $0.toolState?.status.isInFlight == true }
  }

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading, spacing: 6) {
        ForEach(parts) { part in
          HStack(spacing: 6) {
            Text(macToolDisplayName(for: part.tool))
              .font(.caption.weight(.semibold))

            if let subtitle = macToolSubtitle(for: part), !subtitle.isEmpty {
              Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 0)
          }
        }
      }
      .padding(.top, 6)
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .font(.caption)
        Text(hasPendingWork ? "Gathering context..." : "Gathered context")
          .font(.caption.weight(.semibold))
        if !summary.isEmpty {
          Text(summary)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
      }
    }
    .padding(8)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.secondary.opacity(0.08))
    )
  }
}

private struct MacToolPartCard: View {
  let part: MessagePart
  @State private var showOutput = false

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        Image(systemName: macIconName(for: part.tool))
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)

        Text(macToolDisplayName(for: part.tool))
          .font(.caption.weight(.semibold))

        Spacer(minLength: 0)

        Text(part.toolState?.status.rawValue.capitalized ?? "Pending")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      if let subtitle = macToolSubtitle(for: part), !subtitle.isEmpty {
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      if let error = part.toolState?.error, !error.isEmpty {
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
      }

      if let output = part.toolState?.output?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
        DisclosureGroup("Output", isExpanded: $showOutput) {
          ScrollView(.horizontal) {
            Text(output)
              .font(.system(.caption, design: .monospaced))
              .textSelection(.enabled)
              .padding(.top, 4)
          }
        }
      }
    }
    .padding(8)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.secondary.opacity(0.08))
    )
  }
}

private struct MacMarkdownText: View {
  let text: String

  private var attributed: AttributedString? {
    try? AttributedString(
      markdown: text,
      options: AttributedString.MarkdownParsingOptions(
        interpretedSyntax: .full,
        failurePolicy: .returnPartiallyParsedIfPossible
      )
    )
  }

  var body: some View {
    Group {
      if let attributed {
        Text(attributed)
      } else {
        Text(text)
      }
    }
    .textSelection(.enabled)
  }
}

private struct MacTurnDiffSummaryCard: View {
  let diffs: [FileDiff]
  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(spacing: 8) {
        ForEach(diffs) { diff in
          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
              Text(diff.file)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
              Text(diff.status?.capitalized ?? "Modified")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
              Text("+\(diff.additionsCount)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.green)
              Text("-\(diff.deletionsCount)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.red)
            }
          }
        }
      }
      .padding(.top, 6)
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "doc.text")
          .font(.caption)
        Text("Modified \(diffs.count) file\(diffs.count == 1 ? "" : "s")")
          .font(.caption.weight(.semibold))
        Spacer(minLength: 0)
      }
    }
    .padding(8)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.secondary.opacity(0.08))
    )
  }
}

private func macToolDisplayName(for tool: String?) -> String {
  switch tool {
  case "read":
    return "Read"
  case "list":
    return "List"
  case "glob":
    return "Glob"
  case "grep":
    return "Grep"
  case "bash":
    return "Shell"
  case "edit":
    return "Edit"
  case "write":
    return "Write"
  case "apply_patch":
    return "Patch"
  case "question":
    return "Question"
  case "task":
    return "Task"
  case let value:
    return value ?? "Tool"
  }
}

private func macIconName(for tool: String?) -> String {
  switch tool {
  case "bash":
    return "terminal"
  case "read", "glob", "grep", "list":
    return "magnifyingglass"
  case "write", "edit", "apply_patch":
    return "doc.text"
  case "task":
    return "person.2"
  case "question":
    return "questionmark.bubble"
  default:
    return "hammer"
  }
}

private func macToolSubtitle(for part: MessagePart) -> String? {
  switch part.tool {
  case "read":
    return part.toolInputString("filePath")
  case "list":
    return part.toolInputString("path")
  case "glob":
    return part.toolInputString("pattern")
  case "grep":
    return part.toolInputString("pattern")
  case "bash":
    return part.toolInputString("description")
  case "task":
    return part.toolInputString("description")
  default:
    if let title = part.toolState?.title, !title.isEmpty {
      return title
    }
    if let error = part.toolState?.error, !error.isEmpty {
      return error
    }
    return nil
  }
}

private struct MacChangesPane: View {
  let diffs: [FileDiff]

  var body: some View {
    if diffs.isEmpty {
      ContentUnavailableView(
        "No Code Changes",
        systemImage: "doc.text.magnifyingglass",
        description: Text("Run a coding task to populate this diff view.")
      )
    } else {
      List(diffs) { diff in
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 4) {
            Text(diff.file)
              .font(.subheadline.weight(.semibold))
            Text(diff.status?.capitalized ?? "Modified")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()

          VStack(alignment: .trailing, spacing: 2) {
            Text("+\(diff.additionsCount)")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.green)
            Text("-\(diff.deletionsCount)")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.red)
          }
        }
        .padding(.vertical, 2)
      }
      .listStyle(.inset)
    }
  }
}

private struct MacComposerView: View {
  @Bindable var store: WorkspaceStore
  let sessionID: String

  var body: some View {
    VStack(spacing: 10) {
      if let permission = store.currentPermissionRequest(for: sessionID) {
        MacPermissionPromptCard(store: store, sessionID: sessionID, request: permission)
      }

      if let question = store.currentQuestionRequest(for: sessionID) {
        MacQuestionPromptCard(store: store, sessionID: sessionID, request: question)
      }

      TextField("Message", text: $store.draftMessage, axis: .vertical)
        .lineLimit(1 ... 8)

      HStack(spacing: 10) {
        agentMenu

        modelMenu

        Spacer()

        Text(store.statusLabel(for: sessionID))
          .font(.caption)
          .foregroundStyle(.secondary)

        Button(store.isSessionRunning(sessionID) ? "Abort" : "Send") {
          Task {
            if store.isSessionRunning(sessionID) {
              await store.abort(sessionID: sessionID)
            } else {
              await store.sendDraftMessage(in: sessionID)
            }
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!store.isSessionRunning(sessionID) && store.draftMessage.trimmedForInput.isEmpty)
        .keyboardShortcut(.defaultAction)
      }
    }
  }

  private var agentMenu: some View {
    Menu {
      if store.availableAgents.isEmpty {
        Button("No agents available") {}
          .disabled(true)
      } else {
        ForEach(store.availableAgents) { agent in
          Button {
            store.selectAgent(named: agent.name)
          } label: {
            if store.selectedAgentName == agent.name {
              Label(agent.name.capitalized, systemImage: "checkmark")
            } else {
              Text(agent.name.capitalized)
            }
          }
        }
      }
    } label: {
      Label(store.selectedAgentName.capitalized, systemImage: "wand.and.stars")
        .lineLimit(1)
    }
  }

  private var modelMenu: some View {
    Menu {
      if store.modelProviderGroups.isEmpty {
        Button("No models available") {}
          .disabled(true)
      } else {
        ForEach(store.modelProviderGroups) { provider in
          Menu(provider.providerName) {
            ForEach(provider.models) { model in
              Button {
                store.selectModel(model)
              } label: {
                if store.selectedModel?.providerID == model.providerID && store.selectedModel?.modelID == model.modelID {
                  Label(model.displayLabel, systemImage: "checkmark")
                } else {
                  Text(model.displayLabel)
                }
              }
            }
          }
        }
      }
    } label: {
      Label(store.selectedModelDisplayName, systemImage: "cpu")
        .lineLimit(1)
    }
  }
}

private struct MacPermissionPromptCard: View {
  @Bindable var store: WorkspaceStore
  let sessionID: String
  let request: PermissionRequest

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label("Permission Needed", systemImage: "exclamationmark.triangle")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.orange)

      Text(request.permission)
        .font(.subheadline.weight(.semibold))

      if !request.patterns.isEmpty {
        Text(request.patterns.joined(separator: ", "))
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      HStack(spacing: 8) {
        Button("Deny", role: .destructive) {
          Task {
            await store.respondToPermission(sessionID: sessionID, requestID: request.id, reply: .reject)
          }
        }
        .disabled(store.isRespondingToPermission)

        Button("Allow Always") {
          Task {
            await store.respondToPermission(sessionID: sessionID, requestID: request.id, reply: .always)
          }
        }
        .disabled(store.isRespondingToPermission)

        Button("Allow Once") {
          Task {
            await store.respondToPermission(sessionID: sessionID, requestID: request.id, reply: .once)
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.isRespondingToPermission)
      }
      .font(.caption)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.orange.opacity(0.08))
    )
  }
}

private struct MacQuestionPromptCard: View {
  @Bindable var store: WorkspaceStore
  let sessionID: String
  let request: QuestionRequest

  @State private var answerDrafts: [String] = []

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Question", systemImage: "questionmark.bubble")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.blue)

      ForEach(Array(request.questions.enumerated()), id: \.offset) { index, question in
        VStack(alignment: .leading, spacing: 6) {
          Text(question.question)
            .font(.caption.weight(.semibold))

          if !question.options.isEmpty {
            Text(question.options.map(\.label).joined(separator: "  •  "))
              .font(.caption2)
              .foregroundStyle(.secondary)
          }

          TextField(
            question.multiple == true ? "Type one or more answers (comma-separated)" : "Type your answer",
            text: draftBinding(at: index)
          )
          .textFieldStyle(.roundedBorder)
        }
      }

      HStack(spacing: 8) {
        Button("Dismiss", role: .destructive) {
          Task {
            await store.rejectQuestion(sessionID: sessionID, requestID: request.id)
          }
        }
        .disabled(store.isRespondingToQuestion)

        Spacer()

        Button("Submit") {
          Task {
            await store.replyToQuestion(
              sessionID: sessionID,
              requestID: request.id,
              answers: parsedAnswers
            )
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.isRespondingToQuestion || parsedAnswers.allSatisfy(\.isEmpty))
      }
      .font(.caption)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.blue.opacity(0.08))
    )
    .onAppear {
      resetAnswerDrafts()
    }
    .onChange(of: request.id) { _, _ in
      resetAnswerDrafts()
    }
  }

  private var parsedAnswers: [QuestionAnswer] {
    request.questions.enumerated().map { index, question in
      let raw = answerDrafts[safe: index]?.trimmedForInput ?? ""
      guard !raw.isEmpty else {
        return []
      }

      if question.multiple == true {
        return raw
          .split(separator: ",")
          .map { String($0).trimmedForInput }
          .filter { !$0.isEmpty }
      }

      return [raw]
    }
  }

  private func draftBinding(at index: Int) -> Binding<String> {
    Binding(
      get: {
        answerDrafts[safe: index] ?? ""
      },
      set: { value in
        ensureDraftCapacity(at: index)
        answerDrafts[index] = value
      }
    )
  }

  private func ensureDraftCapacity(at index: Int) {
    if index < answerDrafts.count {
      return
    }
    answerDrafts.append(contentsOf: Array(repeating: "", count: (index - answerDrafts.count) + 1))
  }

  private func resetAnswerDrafts() {
    answerDrafts = Array(repeating: "", count: request.questions.count)
  }
}

private extension String {
  var trimmedForInput: String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

private extension Array {
  subscript(safe index: Index) -> Element? {
    guard indices.contains(index) else {
      return nil
    }
    return self[index]
  }
}
#endif
