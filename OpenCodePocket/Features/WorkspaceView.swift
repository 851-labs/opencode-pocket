import OpenCodeModels
import SwiftUI

private enum WorkspacePanel: String, CaseIterable, Identifiable {
  case session = "Session"
  case changes = "Changes"

  var id: Self { self }
}

private enum WorkspaceBootstrapState {
  case loading
  case ready
  case failed(String)
}

struct WorkspaceView: View {
  @Environment(WorkspaceStore.self) private var store

  @State private var selectedPanel: WorkspacePanel = .session
  @State private var bootstrapState: WorkspaceBootstrapState = .loading
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
          await loadWorkspaceBootstrap()
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
    switch bootstrapState {
    case .loading:
      WorkspaceLoadingView()
    case let .failed(message):
      WorkspaceBootstrapErrorView(message: message) {
        Task {
          await loadWorkspaceBootstrap()
        }
      }
    case .ready:
      WorkspacePanelContent(
        selectedSessionID: selectedSessionID,
        selectedPanel: selectedPanel
      )
    }
  }
}

private extension WorkspaceView {
  var workspaceRoot: some View {
    @Bindable var store = store

    return ZStack {
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
      SessionSheet(isPresented: $isDrawerPresented)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("workspace.drawer")
    }
    .safeAreaInset(edge: .bottom) {
      if case .ready = bootstrapState, let selectedSessionID {
        WorkspaceComposer(sessionID: selectedSessionID)
          .padding(.horizontal, 14)
          .padding(.bottom, 8)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
  }

  @ToolbarContentBuilder
  var workspaceToolbar: some ToolbarContent {
    @Bindable var store = store

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

        Toggle(isOn: $store.showReasoningSummaries) {
          Text("Show Reasoning Summaries")
        }
      } label: {
        Image(systemName: "ellipsis")
          .font(.headline)
          .frame(width: 36, height: 36)
      }
      .accessibilityIdentifier("workspace.actions.menu")
    }
  }
}

private extension WorkspaceView {
  func loadWorkspaceBootstrap() async {
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

private struct WorkspaceLoadingView: View {
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

private struct WorkspaceBootstrapErrorView: View {
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

private struct WorkspacePanelContent: View {
  @Environment(WorkspaceStore.self) private var store
  let selectedSessionID: String?
  let selectedPanel: WorkspacePanel

  var body: some View {
    if let selectedSessionID {
      switch selectedPanel {
      case .session:
        SessionTranscriptPane(
          messages: store.messages(for: selectedSessionID),
          sessionStatus: store.status(for: selectedSessionID),
          showReasoningSummaries: store.showReasoningSummaries,
          expandShellToolParts: store.expandShellToolParts,
          expandEditToolParts: store.expandEditToolParts
        )
        .accessibilityIdentifier("workspace.session.pane")
      case .changes:
        ChangesPane(diffs: store.diffs(for: selectedSessionID))
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
