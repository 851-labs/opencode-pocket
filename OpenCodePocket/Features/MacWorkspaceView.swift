#if os(macOS)
import OpenCodeModels
import SwiftUI

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

private enum MacWorkspaceBootstrapState {
  case loading
  case ready
  case failed(String)
}

struct MacWorkspaceView: View {
  @Bindable var store: WorkspaceStore

  @Environment(\.openSettings) private var openSettings

  @State private var selectedPanel: MacWorkspacePanel = .transcript
  @State private var bootstrapState: MacWorkspaceBootstrapState = .loading
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
      await loadWorkspaceBootstrap()
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
    switch bootstrapState {
    case .loading:
      MacWorkspaceLoadingView()
    case let .failed(message):
      MacWorkspaceBootstrapErrorView(message: message) {
        Task {
          await loadWorkspaceBootstrap()
        }
      }
    case .ready:
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

  private func loadWorkspaceBootstrap() async {
    bootstrapState = .loading
    store.clearConnectionError()

    await store.refreshAgentAndModelOptions()
    await store.refreshSessions()

    if let error = store.latestConnectionError, !error.isEmpty, store.sessions.isEmpty {
      bootstrapState = .failed(error)
      return
    }

    bootstrapState = .ready
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

private struct MacWorkspaceLoadingView: View {
  var body: some View {
    ContentUnavailableView {
      ProgressView()
    } description: {
      Text("Loading workspace...")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityIdentifier("workspace.bootstrap.loading")
  }
}

private struct MacWorkspaceBootstrapErrorView: View {
  let message: String
  let retry: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      ContentUnavailableView(
        "Unable to Load Workspace",
        systemImage: "exclamationmark.triangle",
        description: Text(message)
      )

      Button("Retry", action: retry)
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("workspace.bootstrap.retry")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
#endif
