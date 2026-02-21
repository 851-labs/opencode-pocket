#if os(macOS)
import OpenCodeModels
import SwiftUI
import AppKit

private enum MacWorkspacePanel: String, CaseIterable, Identifiable {
  case transcript = "Transcript"
  case changes = "Changes"

  var id: Self { self }
}

private enum MacWorkspaceSheet: Identifiable {
  case renameSession(sessionID: String, currentTitle: String)
  case addProject

  var id: String {
    switch self {
    case let .renameSession(sessionID, _):
      return "rename-\(sessionID)"
    case .addProject:
      return "add-project"
    }
  }
}

struct MacWorkspaceView: View {
  @Bindable var store: WorkspaceStore

  @Environment(\.openSettings) private var openSettings

  @State private var selectedPanel: MacWorkspacePanel = .transcript
  @State private var activeSheet: MacWorkspaceSheet?
  @State private var isDeleteConfirmationPresented = false

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
    .sheet(item: $activeSheet) { sheet in
      switch sheet {
      case let .renameSession(sessionID, currentTitle):
        MacRenameSessionSheet(store: store, sessionID: sessionID, currentTitle: currentTitle)
      case .addProject:
        MacAddProjectSheet(store: store)
      }
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
      ForEach(store.projects) { project in
        MacSidebarProjectSection(store: store, project: project)
      }
    }
    .navigationTitle("Sessions")
    .overlay {
      if store.projects.isEmpty {
        ContentUnavailableView(
          "No Projects",
          systemImage: "folder.badge.plus",
          description: Text("Add a project directory to start browsing sessions.")
        )
      }
    }
  }

  @ViewBuilder
  private var detail: some View {
    if let selectedSessionID {
      MacWorkspaceDetailContent(
        store: store,
        selectedSessionID: selectedSessionID,
        selectedPanel: $selectedPanel
      )
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

      Button {
        activeSheet = .addProject
      } label: {
        Image(systemName: "folder.badge.plus")
      }
      .accessibilityIdentifier("projects.add")
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

        Toggle(isOn: $store.showReasoningSummaries) {
          Text("Show Reasoning Summaries")
        }

        Button("Settings…") {
          openSettings()
        }
      } label: {
        Label("Session Actions", systemImage: "ellipsis.circle")
      }
      .accessibilityIdentifier("workspace.actions.menu")
    }
  }

  private func prepareRenameSession() {
    guard let selectedSessionID else { return }
    activeSheet = .renameSession(
      sessionID: selectedSessionID,
      currentTitle: store.sessionTitle(for: selectedSessionID)
    )
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

}

private struct MacSidebarProjectSection: View {
  @Bindable var store: WorkspaceStore
  let project: SavedProject

  private var sessions: [Session] {
    store.visibleSessions(for: project.id)
  }

  var body: some View {
    Section(project.name) {
      Button {
        store.selectProject(project.id)
      } label: {
        HStack(spacing: 8) {
          Image(systemName: store.selectedProjectID == project.id ? "folder.fill" : "folder")
            .font(.caption)
            .foregroundStyle(.secondary)

          Text(project.directory)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

          Spacer(minLength: 0)
        }
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("sidebar.project.\(project.id)")

      ForEach(sessions) { session in
        MacSidebarSessionRow(store: store, session: session)
      }

      if sessions.isEmpty {
        Text("No sessions yet")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct MacSidebarSessionRow: View {
  @Bindable var store: WorkspaceStore
  let session: Session

  var body: some View {
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

private struct MacWorkspaceDetailContent: View {
  @Bindable var store: WorkspaceStore
  let selectedSessionID: String
  @Binding var selectedPanel: MacWorkspacePanel

  var body: some View {
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
            sessionStatus: store.status(for: selectedSessionID),
            showReasoningSummaries: store.showReasoningSummaries
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
  }
}

private struct MacRenameSessionSheet: View {
  @Environment(\.dismiss) private var dismiss

  @Bindable var store: WorkspaceStore
  let sessionID: String

  @State private var title: String

  init(store: WorkspaceStore, sessionID: String, currentTitle: String) {
    self.store = store
    self.sessionID = sessionID
    _title = State(initialValue: currentTitle)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Rename Session")
        .font(.headline)

      TextField("Session title", text: $title)

      HStack {
        Spacer()

        Button("Cancel") {
          dismiss()
        }

        Button("Save") {
          save()
        }
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(18)
    .frame(width: 360)
  }

  private func save() {
    Task {
      await store.renameSession(sessionID: sessionID, title: title)
      dismiss()
    }
  }
}

private struct MacAddProjectSheet: View {
  @Environment(\.dismiss) private var dismiss

  @Bindable var store: WorkspaceStore

  @State private var directory = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Add Project")
        .font(.headline)

      TextField("/path/to/project", text: $directory)

      HStack {
        Spacer()

        Button("Cancel") {
          dismiss()
        }

        Button("Add") {
          addProject()
        }
        .disabled(directory.trimmedForInput.isEmpty)
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(18)
    .frame(width: 420)
  }

  private func addProject() {
    guard store.addProject(directory: directory) else {
      return
    }

    Task {
      await store.refreshAgentAndModelOptions()
      await store.refreshSessions()
      dismiss()
    }
  }
}

private struct MacTranscriptPane: View {
  let messages: [MessageEnvelope]
  let sessionStatus: SessionStatus
  let showReasoningSummaries: Bool

  @State private var followTail = true
  @State private var hasPendingTail = false
  @State private var visibleTurnLimit = 40

  private let turnBatchSize = 40

  private var turns: [MacTranscriptTurn] {
    MacTranscriptTurn.build(from: messages)
  }

  private var visibleTurns: [MacTranscriptTurn] {
    Array(turns.suffix(visibleTurnLimit))
  }

  private var hiddenTurnCount: Int {
    max(0, turns.count - visibleTurnLimit)
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
              if hiddenTurnCount > 0 {
                Button {
                  visibleTurnLimit += turnBatchSize
                  followTail = false
                } label: {
                  Text("Load earlier (\(hiddenTurnCount))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("workspace.transcript.loadEarlier")
              }

              ForEach(Array(visibleTurns.enumerated()), id: \.element.id) { index, turn in
                MacTurnView(
                  turn: turn,
                  isWorking: index == visibleTurns.count - 1 && sessionStatus.isRunning,
                  showReasoningSummaries: showReasoningSummaries
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
            visibleTurnLimit = max(visibleTurnLimit, turnBatchSize)
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
  let showReasoningSummaries: Bool

  private var latestReasoningHeading: String? {
    turn.assistantMessages
      .flatMap(\.parts)
      .filter { $0.type == "reasoning" }
      .compactMap { $0.text }
      .compactMap(macExtractReasoningHeading)
      .last
  }

  private var hasVisibleAssistantText: Bool {
    turn.assistantMessages
      .flatMap(\.parts)
      .contains { $0.type == "text" && !($0.text?.trimmedForInput ?? "").isEmpty }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let user = turn.user {
        MacUserMessageCard(message: user)
      }

      ForEach(Array(turn.assistantMessages.enumerated()), id: \.element.id) { index, assistant in
        MacAssistantMessageCard(
          message: assistant,
          busy: isWorking && index == turn.assistantMessages.count - 1,
          showReasoningSummaries: showReasoningSummaries
        )
      }

      if isWorking && (!hasVisibleAssistantText || showReasoningSummaries || latestReasoningHeading != nil) {
        HStack(spacing: 8) {
          ProgressView()
            .controlSize(.small)
          Text("Thinking...")
            .font(.caption)
            .foregroundStyle(.secondary)

          if !showReasoningSummaries, let latestReasoningHeading {
            Text(latestReasoningHeading)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
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

  @State private var copied = false
  @State private var isHovering = false

  private var attachments: [MacMessageAttachment] {
    message.parts.compactMap(MacMessageAttachment.init(part:))
  }

  private var metadata: String {
    macUserMessageMetadata(for: message)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if !attachments.isEmpty {
        MacAttachmentStrip(attachments: attachments)
      }

      MacHighlightedUserText(text: message.textBody)
        .font(.body)

      if isHovering || copied {
        HStack(spacing: 8) {
          if !metadata.isEmpty {
            Text(metadata)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }

          Button {
            macCopyText(message.textBody)
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
              copied = false
            }
          } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(copied ? "Copied" : "Copy")
          .accessibilityIdentifier("message.user.copy.\(message.id)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity)
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .trailing)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.accentColor.opacity(0.16))
    )
    .onHover { hovering in
      isHovering = hovering
    }
    .animation(.easeInOut(duration: 0.15), value: isHovering)
    .animation(.easeInOut(duration: 0.15), value: copied)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("User message")
  }
}

private struct MacHighlightedUserText: View {
  let text: String

  private var highlighted: AttributedString {
    macHighlightedUserText(text)
  }

  var body: some View {
    Text(highlighted)
      .textSelection(.enabled)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct MacAttachmentStrip: View {
  let attachments: [MacMessageAttachment]

  var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 8)], spacing: 8) {
      ForEach(attachments) { attachment in
        if let url = URL(string: attachment.url) {
          Link(destination: url) {
            MacAttachmentThumb(attachment: attachment)
          }
          .buttonStyle(.plain)
        } else {
          MacAttachmentThumb(attachment: attachment)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }
}

private struct MacAttachmentThumb: View {
  let attachment: MacMessageAttachment

  var body: some View {
    Group {
      if attachment.isImage, let url = URL(string: attachment.url) {
        AsyncImage(url: url) { phase in
          if let image = phase.image {
            image
              .resizable()
              .scaledToFill()
          } else {
            Color.secondary.opacity(0.15)
              .overlay(Image(systemName: "photo").font(.caption))
          }
        }
      } else {
        Color.secondary.opacity(0.15)
          .overlay(
            Image(systemName: attachment.isPDF ? "doc.richtext" : "doc")
              .font(.caption)
              .foregroundStyle(.secondary)
          )
      }
    }
    .frame(width: 48, height: 48)
    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 6, style: .continuous)
        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
    )
  }
}

private struct MacMessageAttachment: Identifiable {
  let id: String
  let mime: String
  let name: String
  let url: String

  var isImage: Bool {
    mime.hasPrefix("image/")
  }

  var isPDF: Bool {
    mime == "application/pdf"
  }

  init?(part: MessagePart) {
    guard part.type == "file" else {
      return nil
    }
    guard let url = part.fileURL, !url.isEmpty else {
      return nil
    }
    let mime = part.fileMime ?? "application/octet-stream"
    guard mime.hasPrefix("image/") || mime == "application/pdf" else {
      return nil
    }

    id = part.id
    self.mime = mime
    name = part.fileName ?? "Attachment"
    self.url = url
  }
}

private func macHighlightedUserText(_ text: String) -> AttributedString {
  var result = AttributedString(text)
  let nsText = text as NSString
  let fullRange = NSRange(location: 0, length: nsText.length)

  if let fileRegex = try? NSRegularExpression(pattern: #"\[[Ff]ile:[^\]]+\]"#) {
    for match in fileRegex.matches(in: text, range: fullRange) {
      if let range = Range(match.range, in: result) {
        result[range].foregroundColor = .blue
      }
    }
  }

  if let agentRegex = try? NSRegularExpression(pattern: #"@[A-Za-z0-9_\-.]+"#) {
    for match in agentRegex.matches(in: text, range: fullRange) {
      if let range = Range(match.range, in: result) {
        result[range].foregroundColor = .green
      }
    }
  }

  return result
}

private func macUserMessageMetadata(for message: MessageEnvelope) -> String {
  var chunks: [String] = []
  if let agent = message.info.agent?.trimmedForInput, !agent.isEmpty {
    chunks.append(agent.capitalized)
  }
  if let model = message.info.modelID?.trimmedForInput, !model.isEmpty {
    chunks.append(model)
  }
  if let time = macFormattedClockTime(from: message.info.createdAt) {
    chunks.append(time)
  }
  return chunks.joined(separator: " · ")
}

private func macFormattedClockTime(from raw: Double?) -> String? {
  guard let raw else {
    return nil
  }

  let seconds = raw > 10_000_000_000 ? raw / 1000 : raw
  let date = Date(timeIntervalSince1970: seconds)
  let formatter = DateFormatter()
  formatter.dateFormat = "h:mm a"
  return formatter.string(from: date)
}

private func macAssistantMessageMetadata(for message: MessageEnvelope) -> String {
  var chunks: [String] = []
  if let model = message.info.modelID?.trimmedForInput, !model.isEmpty {
    chunks.append(model)
  }
  if let time = macFormattedClockTime(from: message.info.createdAt) {
    chunks.append(time)
  }
  return chunks.joined(separator: " · ")
}

private func macAssistantCopyText(for message: MessageEnvelope, includeReasoning: Bool) -> String {
  let text = message.parts
    .filter { part in
      part.type == "text" || (includeReasoning && part.type == "reasoning")
    }
    .compactMap(\.text)
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { !$0.isEmpty }
    .joined(separator: "\n\n")

  if !text.isEmpty {
    return text
  }

  return message.textBody
}

private func macExtractReasoningHeading(from text: String) -> String? {
  let lines = text
    .components(separatedBy: .newlines)
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { !$0.isEmpty }

  guard let first = lines.first else {
    return nil
  }

  if first.hasPrefix("#") {
    let heading = first.drop { $0 == "#" || $0 == " " }
    return heading.isEmpty ? nil : String(heading)
  }

  return String(first.prefix(80))
}

private func macCopyText(_ text: String) {
  let pasteboard = NSPasteboard.general
  pasteboard.clearContents()
  pasteboard.setString(text, forType: .string)
}

private struct MacToolErrorCard: View {
  let errorText: String

  private var parsed: MacToolErrorDetails {
    macParseToolError(errorText)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(parsed.title)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.red)

      Text(parsed.message)
        .font(.caption)
        .foregroundStyle(.red)

      ForEach(parsed.details, id: \.self) { detail in
        Text(detail)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .padding(8)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.red.opacity(0.08))
    )
  }
}

private struct MacToolErrorDetails {
  let title: String
  let message: String
  let details: [String]
}

private func macParseToolError(_ raw: String) -> MacToolErrorDetails {
  let fallback = MacToolErrorDetails(title: "Tool Error", message: raw, details: [])
  guard
    let data = raw.data(using: .utf8),
    let value = try? JSONDecoder().decode(JSONValue.self, from: data),
    let object = value.objectValue
  else {
    return fallback
  }

  let title = object["title"]?.stringValue ?? object["type"]?.stringValue?.capitalized ?? "Tool Error"
  let message = object["message"]?.stringValue ?? object["error"]?.stringValue ?? raw

  var details: [String] = []
  if let code = object["code"]?.stringValue, !code.isEmpty {
    details.append("Code: \(code)")
  }
  if let path = object["path"]?.stringValue, !path.isEmpty {
    details.append("Path: \(path)")
  }
  if let hint = object["hint"]?.stringValue, !hint.isEmpty {
    details.append("Hint: \(hint)")
  }

  if let errors = object["errors"]?.arrayValue {
    for item in errors.prefix(2) {
      if let text = item.stringValue, !text.isEmpty {
        details.append(text)
      } else if let nested = item.objectValue?["message"]?.stringValue, !nested.isEmpty {
        details.append(nested)
      }
    }
  }

  return MacToolErrorDetails(title: title, message: message, details: details)
}

private struct MacAssistantMessageCard: View {
  let message: MessageEnvelope
  let busy: Bool
  let showReasoningSummaries: Bool

  @State private var isHovering = false

  private var lastTextPartID: String? {
    groupedParts.compactMap { item in
      if case let .part(part) = item,
        part.type == "text",
        !(part.text?.trimmedForInput ?? "").isEmpty
      {
        return part.id
      }
      return nil
    }.last
  }

  private var groupedParts: [MacAssistantItem] {
    let visibleParts = message.parts.filter { part in
      if part.type != "tool" {
        if part.type == "reasoning" {
          return showReasoningSummaries
        }
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
      if groupedParts.isEmpty {
        Text("(Assistant response has no visible parts yet)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      ForEach(Array(groupedParts.enumerated()), id: \.element.id) { index, item in
        switch item {
        case let .part(part):
          MacAssistantPartView(
            part: part,
            message: message,
            showReasoningSummaries: showReasoningSummaries,
            isLastTextPart: part.id == lastTextPartID,
            showMetadataRow: isHovering
          )
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
    .onHover { hovering in
      isHovering = hovering
    }
    .animation(.easeInOut(duration: 0.15), value: isHovering)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Assistant message")
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
  let message: MessageEnvelope
  let showReasoningSummaries: Bool
  let isLastTextPart: Bool
  let showMetadataRow: Bool

  @State private var copied = false

  private var metadata: String {
    macAssistantMessageMetadata(for: message)
  }

  private var copyTextValue: String {
    macAssistantCopyText(for: message, includeReasoning: showReasoningSummaries)
  }

  var body: some View {
    switch part.type {
    case "text":
      if let text = part.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
        VStack(alignment: .leading, spacing: 6) {
          RichMarkdownText(text: text)
            .font(.body)

          if isLastTextPart {
            if showMetadataRow || copied {
              HStack(spacing: 8) {
                if !metadata.isEmpty {
                  Text(metadata)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Button {
                  macCopyText(copyTextValue)
                  copied = true
                  DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    copied = false
                  }
                } label: {
                  Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copied ? "Copied" : "Copy")
                .accessibilityIdentifier("message.assistant.copy")
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .transition(.opacity)
            }
          }
        }
      }
    case "reasoning":
      if
        showReasoningSummaries,
        let text = part.text?.trimmingCharacters(in: .whitespacesAndNewlines),
        !text.isEmpty
      {
        DisclosureGroup(macExtractReasoningHeading(from: text) ?? "Reasoning") {
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
        MacToolErrorCard(errorText: error)
      }

      detailContent

      if let output = part.toolState?.output?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
        DisclosureGroup("Output", isExpanded: $showOutput) {
          RichMarkdownText(text: output)
            .font(.caption)
            .padding(.top, 4)
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
      return macParseToolError(error).message
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

        effortMenu

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
                  Label(model.modelName, systemImage: "checkmark")
                } else {
                  Text(model.modelName)
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

  private var effortMenu: some View {
    Menu {
      Button {
        store.selectModelVariant(nil)
      } label: {
        if store.selectedModelVariant == nil {
          Label("Default", systemImage: "checkmark")
        } else {
          Text("Default")
        }
      }

      ForEach(store.selectedModelVariants, id: \.self) { variant in
        Button {
          store.selectModelVariant(variant)
        } label: {
          if store.selectedModelVariant == variant {
            Label(variant.capitalized, systemImage: "checkmark")
          } else {
            Text(variant.capitalized)
          }
        }
      }
    } label: {
      Text(store.selectedModelVariantDisplayName)
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

  private var linkedToolPart: MessagePart? {
    store.linkedToolPart(for: sessionID, reference: request.tool)
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

      if let linkedToolPart {
        MacPromptToolLinkRow(part: linkedToolPart)
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

private struct MacPromptToolLinkRow: View {
  let part: MessagePart

  private var label: String {
    let tool = macToolDisplayName(for: part.tool)
    let call = part.callID ?? "unknown"
    return "Linked tool: \(tool) (\(call))"
  }

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "link")
        .font(.caption2)
        .foregroundStyle(.secondary)

      Text(label)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(Color.secondary.opacity(0.08))
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

  private var linkedToolPart: MessagePart? {
    store.linkedToolPart(for: sessionID, reference: request.tool)
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
        if let linkedToolPart {
          MacPromptToolLinkRow(part: linkedToolPart)
        }

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

private enum MacSettingsTab: String, CaseIterable, Identifiable {
  case models

  var id: Self { self }

  var title: String {
    switch self {
    case .models:
      return "Models"
    }
  }

  var systemImage: String {
    switch self {
    case .models:
      return "cpu"
    }
  }
}

struct MacSettingsView: View {
  @Bindable var store: WorkspaceStore

  @State private var selectedTab: MacSettingsTab = .models

  var body: some View {
    NavigationSplitView {
      List(MacSettingsTab.allCases, selection: $selectedTab) { tab in
        Label(tab.title, systemImage: tab.systemImage)
          .tag(tab)
      }
      .navigationTitle("Settings")
      .navigationSplitViewColumnWidth(min: 180, ideal: 220)
    } detail: {
      switch selectedTab {
      case .models:
        MacSettingsModelsTab(store: store)
      }
    }
    .task {
      await store.refreshAgentAndModelOptions()
    }
    .frame(minWidth: 860, minHeight: 560)
  }
}

private struct MacSettingsModelsTab: View {
  @Bindable var store: WorkspaceStore

  @State private var query = ""

  private var filteredGroups: [ModelProviderGroup] {
    let search = query.trimmedForInput.lowercased()
    guard !search.isEmpty else {
      return store.modelSettingsProviderGroups
    }

    return store.modelSettingsProviderGroups.compactMap { group in
      let providerMatch = group.providerName.lowercased().contains(search)
      let matches = group.models.filter { model in
        providerMatch
          || model.modelName.lowercased().contains(search)
          || model.modelID.lowercased().contains(search)
      }

      guard !matches.isEmpty else {
        return nil
      }

      return ModelProviderGroup(
        providerID: group.providerID,
        providerName: group.providerName,
        models: matches
      )
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Models")
        .font(.title2.weight(.semibold))

      TextField("Search models", text: $query)
        .textFieldStyle(.roundedBorder)

      if filteredGroups.isEmpty {
        ContentUnavailableView(
          "No Models Found",
          systemImage: "magnifyingglass",
          description: Text("Try a different search term.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(filteredGroups) { group in
              VStack(alignment: .leading, spacing: 8) {
                Text(group.providerName)
                  .font(.headline)

                VStack(spacing: 0) {
                  ForEach(group.models) { model in
                    HStack(spacing: 12) {
                      VStack(alignment: .leading, spacing: 2) {
                        Text(model.modelName)
                          .font(.body)
                          .lineLimit(1)

                        Text(model.modelID)
                          .font(.caption)
                          .foregroundStyle(.secondary)
                          .lineLimit(1)
                      }

                      Spacer(minLength: 0)

                      Toggle(
                        "",
                        isOn: Binding(
                          get: { store.isModelVisible(model) },
                          set: { visible in
                            store.setModelVisibility(model, isVisible: visible)
                          }
                        )
                      )
                      .labelsHidden()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    if model.id != group.models.last?.id {
                      Divider()
                    }
                  }
                }
                .background(
                  RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.1))
                )
              }
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
