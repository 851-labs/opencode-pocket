import SwiftUI
import OpenCodeModels

private enum WorkspacePanel: String, CaseIterable, Identifiable {
  case session = "Session"
  case changes = "Changes"

  var id: Self { self }
}

struct WorkspaceView: View {
  @Bindable var store: WorkspaceStore

  @State private var selectedPanel: WorkspacePanel = .session
  @State private var isDrawerPresented = false
  @State private var isRenamePromptPresented = false
  @State private var isDeleteConfirmationPresented = false
  @State private var renameDraft = ""

  private var selectedSessionID: String? {
    store.selectedSessionID
  }

  var body: some View {
    NavigationStack {
      workspaceRoot
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: isDrawerPresented)
        .task {
          await store.refreshAgentAndModelOptions()
          await store.refreshSessions()
        }
        .alert("Rename Session", isPresented: $isRenamePromptPresented) {
          TextField("Session title", text: $renameDraft)
          Button("Cancel", role: .cancel) {}
          Button("Save") {
            saveRename()
          }
        }
        .alert("Delete Session?", isPresented: $isDeleteConfirmationPresented) {
          Button("Cancel", role: .cancel) {}
          Button("Delete", role: .destructive) {
            deleteSelectedSession()
          }
        } message: {
          Text("This permanently removes the selected chat session.")
        }
    }
  }

  @ViewBuilder
  private var content: some View {
    if let selectedSessionID {
      switch selectedPanel {
      case .session:
        SessionTranscriptPane(
          messages: store.messagesBySession[selectedSessionID] ?? [],
          sessionStatus: store.status(for: selectedSessionID)
        )
          .accessibilityIdentifier("workspace.session.pane")
      case .changes:
        ChangesPane(diffs: store.diffsBySession[selectedSessionID] ?? [])
          .accessibilityIdentifier("workspace.changes.pane")
      }
    } else {
      ContentUnavailableView(
        "No Session Selected",
        systemImage: "bubble.left.and.bubble.right",
        description: Text("Open sessions and choose a session.")
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

// MARK: - Subviews

private extension WorkspaceView {
  var workspaceRoot: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(red: 0.93, green: 0.95, blue: 0.99),
          Color(red: 0.96, green: 0.98, blue: 0.97),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      content
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      workspaceToolbar
    }
    .sheet(isPresented: $isDrawerPresented) {
      SessionSheet(store: store, isPresented: $isDrawerPresented)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("workspace.drawer")
    }
    .safeAreaInset(edge: .bottom) {
      if let selectedSessionID {
        WorkspaceComposer(store: store, sessionID: selectedSessionID)
          .padding(.horizontal, 14)
          .padding(.bottom, 8)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
  }

  @ToolbarContentBuilder
  var workspaceToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button {
        toggleDrawer()
      } label: {
        Image(systemName: "line.3.horizontal")
          .font(.headline)
          .frame(width: 36, height: 36)
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("workspace.drawer.toggle")
    }

    ToolbarItem(placement: .principal) {
      Picker("Panel", selection: $selectedPanel) {
        ForEach(WorkspacePanel.allCases) { panel in
          Text(panel.rawValue).tag(panel)
        }
      }
      .pickerStyle(.segmented)
      .frame(maxWidth: 220)
      .accessibilityIdentifier("workspace.panel.picker")
    }

    ToolbarItem(placement: .topBarTrailing) {
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
          confirmDeleteSession()
        }
        .disabled(selectedSessionID == nil)
      } label: {
        Image(systemName: "ellipsis")
          .font(.headline)
          .frame(width: 36, height: 36)
      }
      .accessibilityIdentifier("workspace.actions.menu")
    }
  }
}

// MARK: - Actions

private extension WorkspaceView {
  func toggleDrawer() {
    isDrawerPresented.toggle()
  }

  func prepareRenameSession() {
    guard let selectedSessionID else { return }
    renameDraft = store.sessionTitle(for: selectedSessionID)
    isRenamePromptPresented = true
  }

  func archiveSelectedSession() {
    guard let selectedSessionID else { return }
    Task {
      await store.archiveSession(sessionID: selectedSessionID)
    }
  }

  func confirmDeleteSession() {
    guard selectedSessionID != nil else { return }
    isDeleteConfirmationPresented = true
  }

  func saveRename() {
    guard let selectedSessionID else { return }
    Task {
      await store.renameSession(sessionID: selectedSessionID, title: renameDraft)
    }
  }

  func deleteSelectedSession() {
    guard let selectedSessionID else { return }
    Task {
      await store.deleteSession(sessionID: selectedSessionID)
    }
  }
}

private struct SessionSheet: View {
  @Bindable var store: WorkspaceStore
  @Binding var isPresented: Bool

  var body: some View {
    NavigationStack {
      List {
        Section("Actions") {
          Button {
            Task {
              await store.refreshSessions()
            }
          } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
          }
          .accessibilityIdentifier("drawer.refresh")

          Button {
            Task {
              await store.createSession()
            }
          } label: {
            Label("New Session", systemImage: "plus")
          }
          .accessibilityIdentifier("drawer.create")
        }

        Section("Sessions") {
          ForEach(store.visibleSessions) { session in
            Button {
              Task {
                await store.selectSession(session.id)
                isPresented = false
              }
            } label: {
              HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                  Text(session.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                  HStack(spacing: 6) {
                    Text(session.id)
                      .font(.caption)
                      .lineLimit(1)
                      .foregroundStyle(.secondary)

                    Circle()
                      .fill(Color.secondary.opacity(0.6))
                      .frame(width: 3, height: 3)

                    Text(store.statusLabel(for: session.id))
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                }

                Spacer()

                if store.selectedSessionID == session.id {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                }
              }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("drawer.session.\(session.id)")
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Sessions")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            isPresented = false
          }
        }
      }
      .accessibilityIdentifier("workspace.drawer")
    }
  }
}

private struct SessionTranscriptPane: View {
  let messages: [MessageEnvelope]
  let sessionStatus: SessionStatus

  private var turns: [TranscriptTurn] {
    TranscriptTurn.build(from: messages)
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 12) {
          if turns.isEmpty {
            ContentUnavailableView(
              "No Messages Yet",
              systemImage: "text.bubble",
              description: Text("Send a message to start this session.")
            )
            .frame(maxWidth: .infinity, minHeight: 320)
          } else {
            ForEach(Array(turns.enumerated()), id: \.element.id) { index, turn in
              TranscriptTurnView(
                turn: turn,
                isWorking: index == turns.count - 1 && sessionStatus.isRunning
              )
              .id(turn.id)
              .accessibilityIdentifier("workspace.turn.\(turn.id)")
            }
          }
        }
        .padding(16)
      }
      .onChange(of: messages.count) { _, _ in
        guard let lastID = turns.last?.id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
          proxy.scrollTo(lastID, anchor: .bottom)
        }
      }
    }
  }
}

private struct TranscriptTurn: Identifiable {
  let id: String
  let user: MessageEnvelope?
  let assistantMessages: [MessageEnvelope]

  static func build(from messages: [MessageEnvelope]) -> [TranscriptTurn] {
    var turns: [TranscriptTurn] = []
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

        turns.append(
          TranscriptTurn(
            id: current.id,
            user: current,
            assistantMessages: assistants
          )
        )
        index = scan
        continue
      }

      if current.info.role == .assistant {
        turns.append(
          TranscriptTurn(
            id: current.id,
            user: nil,
            assistantMessages: [current]
          )
        )
      }

      index += 1
    }

    return turns
  }
}

private struct TranscriptTurnView: View {
  let turn: TranscriptTurn
  let isWorking: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let user = turn.user {
        UserMessageCard(message: user)
      }

      ForEach(turn.assistantMessages) { assistant in
        AssistantMessageCard(message: assistant)
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
        TurnDiffSummaryCard(diffs: user.info.summaryDiffs)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct UserMessageCard: View {
  let message: MessageEnvelope

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("You")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      RichMarkdownText(text: message.textBody)
        .font(.body)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .trailing)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.accentColor.opacity(0.16))
    )
  }
}

private struct AssistantMessageCard: View {
  let message: MessageEnvelope

  private var items: [AssistantRenderItem] {
    let visibleParts = message.parts.filter { part in
      if part.type != "tool" {
        return true
      }

      if part.tool == "todowrite" || part.tool == "todoread" {
        return false
      }

      if part.tool == "question", part.toolState?.status.isInFlight == true {
        return false
      }

      return true
    }

    var result: [AssistantRenderItem] = []
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

      if items.isEmpty {
        Text("(Assistant response has no visible parts yet)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      ForEach(items) { item in
        switch item {
        case let .part(part):
          AssistantPartView(part: part)
        case let .context(_, tools):
          ContextToolGroupCard(parts: tools)
        }
      }

      if let errorText = message.info.errorDisplayText {
        Text(errorText)
          .font(.caption)
          .foregroundStyle(.red)
          .padding(10)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .fill(Color.red.opacity(0.08))
          )
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.white.opacity(0.72))
    )
  }
}

private enum AssistantRenderItem: Identifiable {
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

private struct AssistantPartView: View {
  let part: MessagePart

  var body: some View {
    switch part.type {
    case "text":
      if let text = part.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
        RichMarkdownText(text: text)
          .font(.body)
      }
    case "reasoning":
      if let text = part.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
        DisclosureGroup("Reasoning") {
          RichMarkdownText(text: text)
            .font(.subheadline)
            .padding(.top, 6)
        }
      }
    case "tool":
      ToolPartCard(part: part)
    default:
      if let renderedText = part.renderedText {
        Text(renderedText)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct ContextToolGroupCard: View {
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
            Text(toolDisplayName(for: part.tool))
              .font(.caption.weight(.semibold))

            if let subtitle = toolSubtitle(for: part), !subtitle.isEmpty {
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
    .padding(10)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.secondary.opacity(0.08))
    )
  }
}

private struct ToolPartCard: View {
  let part: MessagePart
  @State private var showOutput = false

  private var toolName: String {
    toolDisplayName(for: part.tool)
  }

  private var statusText: String {
    guard let status = part.toolState?.status else {
      return "Pending"
    }

    switch status {
    case .pending, .running:
      return "Running"
    case .completed:
      return "Done"
    case .error:
      return "Error"
    case let .unknown(value):
      return value.capitalized
    }
  }

  private var statusColor: Color {
    guard let status = part.toolState?.status else {
      return .secondary
    }

    switch status {
    case .pending, .running:
      return .orange
    case .completed:
      return .green
    case .error:
      return .red
    case .unknown:
      return .secondary
    }
  }

  @ViewBuilder
  private var detailContent: some View {
    switch part.tool {
    case "edit":
      ToolEditPreview(part: part)
    case "write":
      ToolWritePreview(part: part)
    case "apply_patch":
      ToolPatchPreview(part: part)
    default:
      EmptyView()
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: iconName(for: part.tool))
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)

        Text(toolName)
          .font(.subheadline.weight(.semibold))

        Spacer(minLength: 0)

        Text(statusText)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(statusColor)
      }

      if let subtitle = toolSubtitle(for: part), !subtitle.isEmpty {
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      if let error = part.toolState?.error, !error.isEmpty {
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
      }

      detailContent

      if let output = part.toolState?.output?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
        DisclosureGroup("Output", isExpanded: $showOutput) {
          ScrollView(.horizontal) {
            Text(output)
              .font(.system(.caption, design: .monospaced))
              .textSelection(.enabled)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.top, 6)
          }
        }
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.secondary.opacity(0.08))
    )
  }
}

private struct ToolEditPreview: View {
  let part: MessagePart
  @State private var isExpanded = false

  private var filePath: String? {
    part.toolInputString("filePath")
  }

  private var beforeText: String? {
    let value = part.toolInputString("oldString")?.trimmingCharacters(in: .whitespacesAndNewlines)
    return value?.isEmpty == true ? nil : value
  }

  private var afterText: String? {
    let value = part.toolInputString("newString")?.trimmingCharacters(in: .whitespacesAndNewlines)
    return value?.isEmpty == true ? nil : value
  }

  var body: some View {
    if beforeText != nil || afterText != nil {
      DisclosureGroup("Edit Preview", isExpanded: $isExpanded) {
        VStack(alignment: .leading, spacing: 8) {
          if let filePath {
            Text(filePath)
              .font(.caption2)
              .foregroundStyle(.secondary)
          }

          if let beforeText {
            ToolSnippetBlock(title: "Before", text: beforeText)
          }

          if let afterText {
            ToolSnippetBlock(title: "After", text: afterText)
          }
        }
        .padding(.top, 6)
      }
      .font(.caption)
    }
  }
}

private struct ToolWritePreview: View {
  let part: MessagePart
  @State private var isExpanded = false

  private var filePath: String? {
    part.toolInputString("filePath")
  }

  private var content: String? {
    let value = part.toolInputString("content")?.trimmingCharacters(in: .whitespacesAndNewlines)
    return value?.isEmpty == true ? nil : value
  }

  var body: some View {
    if let content {
      DisclosureGroup("Written Content", isExpanded: $isExpanded) {
        VStack(alignment: .leading, spacing: 8) {
          if let filePath {
            Text(filePath)
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
          ToolSnippetBlock(title: "Content", text: content)
        }
        .padding(.top, 6)
      }
      .font(.caption)
    }
  }
}

private struct ToolPatchPreview: View {
  let part: MessagePart
  @State private var isExpanded = false

  private var files: [String] {
    let fromInput = part.toolState?.input["files"]?.arrayValue?.compactMap { $0.stringValue } ?? []
    if !fromInput.isEmpty {
      return fromInput
    }
    return part.files
  }

  private var patchText: String? {
    let value = part.toolInputString("patchText")?.trimmingCharacters(in: .whitespacesAndNewlines)
    return value?.isEmpty == true ? nil : value
  }

  var body: some View {
    if !files.isEmpty || patchText != nil {
      VStack(alignment: .leading, spacing: 6) {
        if !files.isEmpty {
          VStack(alignment: .leading, spacing: 4) {
            Text("Files")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(.secondary)
            ForEach(files, id: \.self) { file in
              Text(file)
                .font(.caption2)
                .lineLimit(2)
            }
          }
        }

        if let patchText {
          DisclosureGroup("Patch Text", isExpanded: $isExpanded) {
            ToolSnippetBlock(title: "Patch", text: patchText)
              .padding(.top, 6)
          }
          .font(.caption)
        }
      }
    }
  }
}

private struct ToolSnippetBlock: View {
  let title: String
  let text: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)

      ScrollView(.horizontal) {
        Text(text)
          .font(.system(.caption, design: .monospaced))
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(8)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color.secondary.opacity(0.07))
      )
    }
  }
}

private struct TurnDiffSummaryCard: View {
  let diffs: [FileDiff]
  @State private var isExpanded = false

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(spacing: 8) {
        ForEach(diffs) { diff in
          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
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
    .padding(10)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.secondary.opacity(0.08))
    )
  }
}

private func toolDisplayName(for tool: String?) -> String {
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
  case "webfetch":
    return "Web"
  case "question":
    return "Question"
  case "task":
    return "Agent"
  case let value:
    return value ?? "Tool"
  }
}

private func iconName(for tool: String?) -> String {
  switch tool {
  case "bash":
    return "terminal"
  case "read", "glob", "grep", "list":
    return "magnifyingglass"
  case "webfetch":
    return "globe"
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

private func toolSubtitle(for part: MessagePart) -> String? {
  switch part.tool {
  case "read":
    return displayPathComponent(part.toolInputString("filePath"))
  case "list":
    return displayPathComponent(part.toolInputString("path"))
  case "glob":
    return part.toolInputString("pattern")
  case "grep":
    return part.toolInputString("pattern")
  case "webfetch":
    return part.toolInputString("url")
  case "bash":
    return part.toolInputString("description")
  case "edit", "write":
    return displayPathComponent(part.toolInputString("filePath"))
  case "apply_patch":
    let fileCount = part.toolState?.input["files"]?.arrayValue?.count ?? 0
    if fileCount > 0 {
      return "\(fileCount) file\(fileCount == 1 ? "" : "s")"
    }
    return nil
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

private func displayPathComponent(_ rawPath: String?) -> String? {
  guard let rawPath else {
    return nil
  }

  let trimmed = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !trimmed.isEmpty else {
    return nil
  }

  let component = trimmed
    .split(whereSeparator: { $0 == "/" || $0 == "\\" })
    .last
    .map(String.init)
  return component?.isEmpty == false ? component : trimmed
}

private struct ChangesPane: View {
  let diffs: [FileDiff]

  var body: some View {
    if diffs.isEmpty {
      ContentUnavailableView(
        "No Code Changes",
        systemImage: "doc.text.magnifyingglass",
        description: Text("Run a coding task to populate this diff view.")
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .accessibilityIdentifier("changes.empty")
    } else {
      ScrollView {
        LazyVStack(spacing: 10) {
          ForEach(diffs) { diff in
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 6) {
                Text(diff.file)
                  .font(.subheadline.weight(.semibold))
                  .lineLimit(2)

                Text(diff.status?.capitalized ?? "Modified")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }

              Spacer()

              VStack(alignment: .trailing, spacing: 4) {
                Text("+\(diff.additionsCount)")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.green)

                Text("-\(diff.deletionsCount)")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.red)
              }
            }
            .padding(12)
            .background(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.72))
            )
            .accessibilityIdentifier("changes.row.\(diff.id)")
          }
        }
        .padding(16)
      }
      .accessibilityIdentifier("changes.list")
    }
  }
}

private struct WorkspaceComposer: View {
  @Bindable var store: WorkspaceStore
  let sessionID: String

  var body: some View {
    GlassEffectContainer(spacing: 0) {
      composerBody
        .glassEffect(
          .regular
            .tint(Color.white.opacity(0.12))
            .interactive(),
          in: .rect(cornerRadius: 22)
        )
        .scrollEdgeEffectStyle(.soft, for: .bottom)
    }
  }

  private var composerBody: some View {
    VStack(spacing: 10) {
      if let permission = store.currentPermissionRequest(for: sessionID) {
        PermissionPromptCard(
          store: store,
          sessionID: sessionID,
          request: permission
        )
      }

      if let question = store.currentQuestionRequest(for: sessionID) {
        QuestionPromptCard(
          store: store,
          sessionID: sessionID,
          request: question
        )
      }

      let composerBlocked = store.isComposerBlocked(for: sessionID)
      let isRunning = store.isSessionRunning(sessionID)

      HStack(alignment: .bottom, spacing: 10) {
        TextField("Message", text: $store.draftMessage, axis: .vertical)
          .lineLimit(1 ... 6)
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          .disabled(composerBlocked)
          .accessibilityIdentifier("composer.input")

        Button {
          Task {
            if store.isSessionRunning(sessionID) {
              await store.abort(sessionID: sessionID)
            } else {
              await store.sendDraftMessage(in: sessionID)
            }
          }
        } label: {
          Image(systemName: store.isSessionRunning(sessionID) ? "stop.fill" : "arrow.up")
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 42, height: 42)
            .background(Circle().fill(Color.accentColor))
        }
        .buttonStyle(.plain)
        .disabled(!isRunning && (composerBlocked || store.draftMessage.trimmedForInput.isEmpty))
        .accessibilityIdentifier("composer.sendAbort")
        .accessibilityLabel(store.isSessionRunning(sessionID) ? "Abort" : "Send")
      }

      if composerBlocked {
        Text("Respond to the active prompt before sending another message.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      HStack(spacing: 8) {
        agentMenu

        modelMenu

        Spacer()

        Text(store.statusLabel(for: sessionID))
          .font(.caption)
          .foregroundStyle(.secondary)
          .accessibilityIdentifier("composer.status")
      }
    }
    .padding(12)
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
        .font(.caption.weight(.semibold))
        .lineLimit(1)
    }
    .accessibilityIdentifier("composer.agentMenu")
    .accessibilityLabel("Agent Menu")
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
        .font(.caption.weight(.semibold))
        .lineLimit(1)
    }
    .accessibilityIdentifier("composer.modelMenu")
    .accessibilityLabel("Model Menu")
  }
}

private struct PermissionPromptCard: View {
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
            await store.respondToPermission(
              sessionID: sessionID,
              requestID: request.id,
              reply: .reject
            )
          }
        }
        .disabled(store.isRespondingToPermission(requestID: request.id))

        Button("Allow Always") {
          Task {
            await store.respondToPermission(
              sessionID: sessionID,
              requestID: request.id,
              reply: .always
            )
          }
        }
        .disabled(store.isRespondingToPermission(requestID: request.id))

        Button("Allow Once") {
          Task {
            await store.respondToPermission(
              sessionID: sessionID,
              requestID: request.id,
              reply: .once
            )
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.isRespondingToPermission(requestID: request.id))
      }
      .font(.caption)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color.orange.opacity(0.08))
    )
  }
}

private struct QuestionPromptCard: View {
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
            let selected = selectedLabels(at: index)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 6)], spacing: 6) {
              ForEach(question.options, id: \.label) { option in
                let isSelected = selected.contains(option.label)

                Button {
                  selectOption(option.label, at: index, multiple: question.multiple == true)
                } label: {
                  VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                      .font(.caption.weight(.semibold))
                      .lineLimit(1)

                    if !option.description.isEmpty {
                      Text(option.description)
                        .font(.caption2)
                        .lineLimit(2)
                    }
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 6)
                  .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                      .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                  )
                }
                .buttonStyle(.plain)
              }
            }
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
        .disabled(store.isRespondingToQuestion(requestID: request.id))

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
        .disabled(store.isRespondingToQuestion(requestID: request.id) || parsedAnswers.allSatisfy(\.isEmpty))
      }
      .font(.caption)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
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

  private func selectedLabels(at index: Int) -> [String] {
    let raw = answerDrafts[safe: index]?.trimmedForInput ?? ""
    guard !raw.isEmpty else {
      return []
    }
    return raw
      .split(separator: ",")
      .map { String($0).trimmedForInput }
      .filter { !$0.isEmpty }
  }

  private func selectOption(_ option: String, at index: Int, multiple: Bool) {
    ensureDraftCapacity(at: index)

    if !multiple {
      answerDrafts[index] = option
      return
    }

    var selected = selectedLabels(at: index)
    if let selectedIndex = selected.firstIndex(of: option) {
      selected.remove(at: selectedIndex)
    } else {
      selected.append(option)
    }

    answerDrafts[index] = selected.joined(separator: ", ")
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
