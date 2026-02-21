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

  @State private var followTail = true
  @State private var hasPendingTail = false

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
      ScrollViewReader { proxy in
        ZStack(alignment: .bottomTrailing) {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
              ForEach(Array(turns.enumerated()), id: \.element.id) { index, turn in
                MacTurnView(
                  turn: turn,
                  isWorking: index == turns.count - 1 && sessionStatus.isRunning
                )
                .id(turn.id)
              }
            }
            .padding(16)
          }
          .simultaneousGesture(
            DragGesture(minimumDistance: 8)
              .onChanged { value in
                if value.translation.height > 16 {
                  followTail = false
                }
              }
          )
          .onChange(of: messages.count) { _, _ in
            guard let lastID = turns.last?.id else { return }
            if followTail {
              withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastID, anchor: .bottom)
              }
              hasPendingTail = false
              return
            }
            hasPendingTail = true
          }
          .onChange(of: followTail) { _, shouldFollow in
            guard shouldFollow, let lastID = turns.last?.id else {
              return
            }
            withAnimation(.easeOut(duration: 0.2)) {
              proxy.scrollTo(lastID, anchor: .bottom)
            }
            hasPendingTail = false
          }

          if hasPendingTail {
            Button {
              followTail = true
            } label: {
              Label("Jump to latest", systemImage: "arrow.down.circle.fill")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .foregroundStyle(.white)
                .background(
                  Capsule(style: .continuous)
                    .fill(Color.accentColor)
                )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
            .padding(.bottom, 14)
            .accessibilityIdentifier("workspace.transcript.resume")
          }
        }
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

      ForEach(Array(turn.assistantMessages.enumerated()), id: \.element.id) { index, assistant in
        MacAssistantMessageCard(
          message: assistant,
          busy: isWorking && index == turn.assistantMessages.count - 1
        )
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

      RichMarkdownText(text: message.textBody)
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
  let busy: Bool

  private var groupedParts: [MacAssistantItem] {
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

      ForEach(Array(groupedParts.enumerated()), id: \.element.id) { index, item in
        switch item {
        case let .part(part):
          MacAssistantPartView(part: part)
        case let .context(_, tools):
          MacContextToolGroupCard(parts: tools, busy: busy && index == groupedParts.count - 1)
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
  let busy: Bool
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
    busy || parts.contains { $0.toolState?.status.isInFlight == true }
  }

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading, spacing: 6) {
        ForEach(parts) { part in
          let running = part.toolState?.status.isInFlight == true || (busy && part.id == parts.last?.id)
          let args = macContextToolArgs(for: part)
          HStack(spacing: 6) {
            Text(macToolDisplayName(for: part.tool))
              .font(.caption.weight(.semibold))
              .redacted(reason: running ? .placeholder : [])

            if !running, let subtitle = macContextToolSubtitle(for: part), !subtitle.isEmpty {
              Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            if !running, !args.isEmpty {
              Text(args.joined(separator: " "))
                .font(.caption2)
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
      MacToolEditPreview(part: part)
    case "write":
      MacToolWritePreview(part: part)
    case "apply_patch":
      MacToolPatchPreview(part: part)
    default:
      EmptyView()
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        Image(systemName: macIconName(for: part.tool))
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)

        Text(macToolDisplayName(for: part.tool))
          .font(.caption.weight(.semibold))

        Spacer(minLength: 0)

        Text(statusText)
          .font(.caption2)
          .foregroundStyle(statusColor)
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

      detailContent

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

private struct MacToolEditPreview: View {
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
            MacToolSnippetBlock(title: "Before", text: beforeText)
          }

          if let afterText {
            MacToolSnippetBlock(title: "After", text: afterText)
          }
        }
        .padding(.top, 6)
      }
      .font(.caption)
    }
  }
}

private struct MacToolWritePreview: View {
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
          MacToolSnippetBlock(title: "Content", text: content)
        }
        .padding(.top, 6)
      }
      .font(.caption)
    }
  }
}

private struct MacToolPatchPreview: View {
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
            MacToolSnippetBlock(title: "Patch", text: patchText)
              .padding(.top, 6)
          }
          .font(.caption)
        }
      }
    }
  }
}

private struct MacToolSnippetBlock: View {
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

private struct MacTurnDiffSummaryCard: View {
  let diffs: [FileDiff]
  @State private var isExpanded = false

  private var dedupedDiffs: [FileDiff] {
    var seen: Set<String> = []
    return diffs
      .reversed()
      .filter { seen.insert($0.file).inserted }
      .reversed()
  }

  @State private var expandedFiles: Set<String> = []

  private func isExpandedBinding(for file: String) -> Binding<Bool> {
    Binding(
      get: {
        expandedFiles.contains(file)
      },
      set: { value in
        if value {
          expandedFiles.insert(file)
          return
        }
        expandedFiles.remove(file)
      }
    )
  }

  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(spacing: 8) {
        ForEach(dedupedDiffs) { diff in
          DisclosureGroup(isExpanded: isExpandedBinding(for: diff.file)) {
            VStack(alignment: .leading, spacing: 8) {
              MacDiffSnippet(title: "Before", text: diff.before)
              MacDiffSnippet(title: "After", text: diff.after)
            }
            .padding(.top, 6)
          } label: {
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 2) {
                MacDiffPathLabel(path: diff.file)
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
      }
      .padding(.top, 6)
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "doc.text")
          .font(.caption)
        Text("Modified \(dedupedDiffs.count) file\(dedupedDiffs.count == 1 ? "" : "s")")
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

private struct MacDiffPathLabel: View {
  let path: String

  private var split: (directory: String?, fileName: String) {
    let parts = path.split(separator: "/", omittingEmptySubsequences: false)
    guard let last = parts.last else {
      return (nil, path)
    }

    let fileName = String(last)
    let prefix = parts.dropLast().joined(separator: "/")
    if prefix.isEmpty {
      return (nil, fileName)
    }
    return (prefix + "/", fileName)
  }

  var body: some View {
    HStack(spacing: 0) {
      if let directory = split.directory {
        Text(directory)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.middle)
      }

      Text(split.fileName)
        .font(.caption.weight(.semibold))
        .lineLimit(1)
        .truncationMode(.middle)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(path)
  }
}

private struct MacDiffSnippet: View {
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

private func macIconName(for tool: String?) -> String {
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

private func macToolSubtitle(for part: MessagePart) -> String? {
  switch part.tool {
  case "read":
    return macDisplayPathComponent(part.toolInputString("filePath"))
  case "list":
    return macDisplayPathComponent(part.toolInputString("path"))
  case "glob":
    return part.toolInputString("pattern")
  case "grep":
    return part.toolInputString("pattern")
  case "webfetch":
    return part.toolInputString("url")
  case "bash":
    return part.toolInputString("description")
  case "edit", "write":
    return macDisplayPathComponent(part.toolInputString("filePath"))
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

private func macContextToolSubtitle(for part: MessagePart) -> String? {
  switch part.tool {
  case "read":
    return macDisplayPathComponent(part.toolInputString("filePath"))
  case "list", "glob", "grep":
    return part.toolInputString("path")
  default:
    return macToolSubtitle(for: part)
  }
}

private func macContextToolArgs(for part: MessagePart) -> [String] {
  switch part.tool {
  case "read":
    var args: [String] = []
    if let offset = macFormattedToolNumber(part.toolInputNumber("offset")) {
      args.append("offset=\(offset)")
    }
    if let limit = macFormattedToolNumber(part.toolInputNumber("limit")) {
      args.append("limit=\(limit)")
    }
    return args
  case "glob":
    if let pattern = part.toolInputString("pattern"), !pattern.isEmpty {
      return ["pattern=\(pattern)"]
    }
    return []
  case "grep":
    var args: [String] = []
    if let pattern = part.toolInputString("pattern"), !pattern.isEmpty {
      args.append("pattern=\(pattern)")
    }
    if let include = part.toolInputString("include"), !include.isEmpty {
      args.append("include=\(include)")
    }
    return args
  default:
    return []
  }
}

private func macFormattedToolNumber(_ number: Double?) -> String? {
  guard let number else {
    return nil
  }

  let rounded = number.rounded()
  if abs(number - rounded) < 0.000_001 {
    return String(Int(rounded))
  }
  return String(number)
}

private func macDisplayPathComponent(_ rawPath: String?) -> String? {
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
              .lineLimit(2)
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

      let todos = store.todosBySession[sessionID] ?? []
      if !todos.isEmpty {
        MacTodoDockCard(todos: todos)
      }

      let composerBlocked = store.isComposerBlocked(for: sessionID)
      let isRunning = store.isSessionRunning(sessionID)

      TextField("Message", text: $store.draftMessage, axis: .vertical)
        .lineLimit(1 ... 8)
        .disabled(composerBlocked)

      if composerBlocked {
        Text("Respond to the active prompt before sending another message.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

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
        .disabled(!isRunning && (composerBlocked || store.draftMessage.trimmedForInput.isEmpty))
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

private struct MacTodoDockCard: View {
  let todos: [TodoItem]
  @State private var isCollapsed = false

  private var completedCount: Int {
    todos.filter { $0.status == "completed" }.count
  }

  private var allDone: Bool {
    !todos.isEmpty && todos.allSatisfy { $0.status == "completed" || $0.status == "cancelled" }
  }

  private var summary: String {
    "\(completedCount) of \(todos.count) tasks completed"
  }

  private var preview: String {
    todos.first(where: { $0.status == "in_progress" })?.content
      ?? todos.first(where: { $0.status == "pending" })?.content
      ?? todos.last?.content
      ?? ""
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Text(summary)
          .font(.caption)
          .foregroundStyle(.secondary)

        if isCollapsed && !preview.isEmpty {
          Text(preview)
            .font(.caption)
            .lineLimit(1)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 0)

        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            isCollapsed.toggle()
          }
        } label: {
          Image(systemName: "chevron.down")
            .font(.caption.weight(.semibold))
            .rotationEffect(.degrees(isCollapsed ? 0 : 180))
        }
        .buttonStyle(.plain)
      }

      if !isCollapsed {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(todos) { todo in
            HStack(alignment: .top, spacing: 8) {
              Image(systemName: todoIconName(todo.status))
                .font(.caption)
                .foregroundStyle(todoIconColor(todo.status))

              Text(todo.content)
                .font(.caption)
                .foregroundStyle(todo.status == "completed" || todo.status == "cancelled" ? .secondary : .primary)
                .strikethrough(todo.status == "completed" || todo.status == "cancelled")
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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
    .onChange(of: allDone) { _, done in
      if done {
        withAnimation(.easeInOut(duration: 0.25)) {
          isCollapsed = true
        }
      }
    }
  }

  private func todoIconName(_ status: String) -> String {
    switch status {
    case "completed":
      return "checkmark.circle.fill"
    case "in_progress":
      return "circle.fill"
    case "cancelled":
      return "xmark.circle"
    default:
      return "circle"
    }
  }

  private func todoIconColor(_ status: String) -> Color {
    switch status {
    case "completed":
      return .green
    case "in_progress":
      return .blue
    case "cancelled":
      return .secondary
    default:
      return .secondary
    }
  }
}

private struct MacPermissionPromptCard: View {
  @Bindable var store: WorkspaceStore
  let sessionID: String
  let request: PermissionRequest

  private var hint: String? {
    macPermissionHint(for: request.permission)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label("Permission Needed", systemImage: "exclamationmark.triangle")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.orange)

      Text(request.permission)
        .font(.subheadline.weight(.semibold))

      if let hint {
        Text(hint)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      if !request.patterns.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          ForEach(request.patterns, id: \.self) { pattern in
            Text(pattern)
              .font(.system(.caption, design: .monospaced))
              .textSelection(.enabled)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                  .fill(Color.secondary.opacity(0.08))
              )
          }
        }
      }

      HStack(spacing: 8) {
        Button("Deny", role: .destructive) {
          Task {
            await store.respondToPermission(sessionID: sessionID, requestID: request.id, reply: .reject)
          }
        }
        .disabled(store.isRespondingToPermission(requestID: request.id))

        Button("Allow Always") {
          Task {
            await store.respondToPermission(sessionID: sessionID, requestID: request.id, reply: .always)
          }
        }
        .disabled(store.isRespondingToPermission(requestID: request.id))

        Button("Allow Once") {
          Task {
            await store.respondToPermission(sessionID: sessionID, requestID: request.id, reply: .once)
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
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.orange.opacity(0.08))
    )
  }
}

private func macPermissionHint(for permission: String) -> String? {
  switch permission {
  case "read":
    return "Allow the assistant to read files from your workspace."
  case "write":
    return "Allow the assistant to create new files in your workspace."
  case "edit":
    return "Allow the assistant to modify existing files."
  case "bash":
    return "Allow the assistant to run shell commands."
  case "webfetch":
    return "Allow the assistant to fetch content from external URLs."
  case "task":
    return "Allow the assistant to launch sub-agents for delegated tasks."
  default:
    return nil
  }
}

private struct MacQuestionPromptCard: View {
  @Bindable var store: WorkspaceStore
  let sessionID: String
  let request: QuestionRequest

  @State private var tab = 0
  @State private var answers: [QuestionAnswer] = []
  @State private var customAnswers: [String] = []
  @State private var isEditingCustom = false

  private var total: Int {
    request.questions.count
  }

  private var question: QuestionInfo? {
    guard request.questions.indices.contains(tab) else {
      return nil
    }
    return request.questions[tab]
  }

  private var options: [QuestionOption] {
    question?.options ?? []
  }

  private var isMultiple: Bool {
    question?.multiple == true
  }

  private var isSending: Bool {
    store.isRespondingToQuestion(requestID: request.id)
  }

  private var isLastQuestion: Bool {
    tab >= total - 1
  }

  private var summary: String {
    guard total > 0 else {
      return "0 of 0 questions"
    }
    let current = min(tab + 1, total)
    return "\(current) of \(total) questions"
  }

  private var customInput: String {
    customAnswers[safe: tab] ?? ""
  }

  private var selectedAnswers: [String] {
    answers[safe: tab] ?? []
  }

  private var parsedAnswers: [QuestionAnswer] {
    request.questions.enumerated().map { index, _ in
      let raw = answers[safe: index] ?? []
      var unique: [String] = []
      for value in raw.map(\.trimmedForInput).filter({ !$0.isEmpty }) where !unique.contains(value) {
        unique.append(value)
      }
      return unique
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center, spacing: 10) {
        Text(summary)
          .font(.caption.weight(.semibold))

        Spacer(minLength: 0)

        HStack(spacing: 6) {
          ForEach(Array(request.questions.enumerated()), id: \.offset) { index, _ in
            let answered = (answers[safe: index]?.isEmpty == false)
            let active = index == tab
            Button {
              guard !isSending else { return }
              tab = index
              isEditingCustom = false
            } label: {
              Capsule(style: .continuous)
                .fill(active ? Color.primary : (answered ? Color.accentColor : Color.secondary.opacity(0.35)))
                .frame(width: 16, height: 3)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("question.progress.\(index)")
          }
        }
      }

      if let question {
        Text(question.question)
          .font(.caption.weight(.semibold))

        Text(isMultiple ? "Choose one or more options." : "Choose one option.")
          .font(.caption)
          .foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 6) {
          ForEach(options, id: \.label) { option in
            let isSelected = selectedAnswers.contains(option.label)

            Button {
              guard !isSending else { return }
              selectOption(option.label)
            } label: {
              HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                  .font(.caption)
                  .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

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

                Spacer(minLength: 0)
              }
              .padding(.horizontal, 8)
              .padding(.vertical, 8)
              .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                  .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
              )
            }
            .buttonStyle(.plain)
            .disabled(isSending)
          }

          if isEditingCustom {
            HStack(spacing: 8) {
              TextField("Type your answer", text: customBinding)
                .textFieldStyle(.roundedBorder)
                .disabled(isSending)

              Button("Add") {
                commitCustomAnswer()
              }
              .buttonStyle(.borderedProminent)
              .disabled(isSending)

              Button("Cancel") {
                isEditingCustom = false
              }
              .disabled(isSending)
            }
          } else {
            let picked = selectedAnswers.contains(customInput.trimmedForInput) && !customInput.trimmedForInput.isEmpty
            Button {
              guard !isSending else { return }
              isEditingCustom = true
            } label: {
              HStack(spacing: 10) {
                Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                  .font(.caption)
                  .foregroundStyle(picked ? Color.accentColor : Color.secondary)

                VStack(alignment: .leading, spacing: 2) {
                  Text("Type your own answer")
                    .font(.caption.weight(.semibold))
                  if !customInput.trimmedForInput.isEmpty {
                    Text(customInput)
                      .font(.caption2)
                      .foregroundStyle(.secondary)
                      .lineLimit(2)
                  }
                }

                Spacer(minLength: 0)
              }
              .padding(.horizontal, 8)
              .padding(.vertical, 8)
              .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                  .fill(Color.secondary.opacity(0.08))
              )
            }
            .buttonStyle(.plain)
            .disabled(isSending)
          }
        }
      }

      HStack(spacing: 8) {
        Button("Dismiss", role: .destructive) {
          Task {
            await store.rejectQuestion(sessionID: sessionID, requestID: request.id)
          }
        }
        .disabled(isSending)

        if tab > 0 {
          Button("Back") {
            guard !isSending else { return }
            tab -= 1
            isEditingCustom = false
          }
          .disabled(isSending)
        }

        Spacer()

        Button(isLastQuestion ? "Submit" : "Next") {
          if isEditingCustom {
            commitCustomAnswer()
          }

          if !isLastQuestion {
            tab += 1
            isEditingCustom = false
            return
          }

          Task {
            await store.replyToQuestion(sessionID: sessionID, requestID: request.id, answers: parsedAnswers)
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isSending || parsedAnswers.allSatisfy(\.isEmpty))
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
      resetState()
    }
    .onChange(of: request.id) { _, _ in
      resetState()
    }
  }

  private var customBinding: Binding<String> {
    Binding(
      get: {
        customAnswers[safe: tab] ?? ""
      },
      set: { value in
        ensureCapacity(for: tab)
        customAnswers[tab] = value
      }
    )
  }

  private func selectOption(_ option: String) {
    ensureCapacity(for: tab)

    if !isMultiple {
      answers[tab] = [option]
      isEditingCustom = false
      return
    }

    var selected = answers[tab]
    if let selectedIndex = selected.firstIndex(of: option) {
      selected.remove(at: selectedIndex)
    } else {
      selected.append(option)
    }

    answers[tab] = selected
  }

  private func commitCustomAnswer() {
    let value = customInput.trimmedForInput
    ensureCapacity(for: tab)
    customAnswers[tab] = value

    guard !value.isEmpty else {
      isEditingCustom = false
      return
    }

    if isMultiple {
      if !answers[tab].contains(value) {
        answers[tab].append(value)
      }
      isEditingCustom = false
      return
    }

    answers[tab] = [value]
    isEditingCustom = false
  }

  private func ensureCapacity(for index: Int) {
    if index < answers.count {
      return
    }

    let growBy = (index - answers.count) + 1
    answers.append(contentsOf: Array(repeating: [], count: growBy))
    customAnswers.append(contentsOf: Array(repeating: "", count: growBy))
  }

  private func resetState() {
    tab = 0
    answers = Array(repeating: [], count: request.questions.count)
    customAnswers = Array(repeating: "", count: request.questions.count)
    isEditingCustom = false
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
