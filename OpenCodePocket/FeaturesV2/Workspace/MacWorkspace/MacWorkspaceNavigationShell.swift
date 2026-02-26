#if os(macOS)
  import SwiftUI
  import UniformTypeIdentifiers

  enum MacWorkspacePanel: String, CaseIterable, Identifiable {
    case transcript = "Transcript"
    case changes = "Changes"

    var id: Self { self }
  }

  enum MacWorkspaceSheet: Identifiable {
    case renameSession(sessionID: String, currentTitle: String)

    var id: String {
      switch self {
      case let .renameSession(sessionID, _):
        return "rename-\(sessionID)"
      }
    }
  }

  enum MacWorkspaceBootstrapState {
    case loading
    case ready
    case failed(String)
  }

  struct MacWorkspaceNavigationShell: View {
    @Environment(WorkspaceStore.self) private var store

    @State private var selectedPanel: MacWorkspacePanel = .transcript
    @State private var bootstrapState: MacWorkspaceBootstrapState = .loading
    @State private var activeSheet: MacWorkspaceSheet?
    @State private var isProjectPickerPresented = false
    @State private var pendingDeleteSessionID: String?
    @State private var expandedProjectIDs: Set<String> = []
    @State private var selectionTask: Task<Void, Never>?

    private var selectedSessionID: String? {
      store.selectedSessionID
    }

    private var navigationTitle: String {
      guard let selectedSessionID else {
        return "OpenCode Pocket"
      }
      return store.sessionTitle(for: selectedSessionID)
    }

    var body: some View {
      NavigationSplitView {
        MacWorkspaceSidebar(
          selectedSession: selectedSessionBinding,
          expandedProjectIDs: $expandedProjectIDs,
          onSelectProject: selectProjectFromSidebar,
          onPresentProjectPicker: presentProjectPicker,
          onTogglePinSession: togglePinSession,
          onRenameSession: prepareRenameSession,
          onArchiveSession: archiveSession,
          onDeleteSession: confirmDeleteSession
        )
      } detail: {
        MacWorkspaceDetail(
          bootstrapState: bootstrapState,
          selectedSessionID: selectedSessionID,
          selectedPanel: $selectedPanel,
          retry: retryBootstrap
        )
      }
      .navigationSplitViewStyle(.balanced)
      .navigationTitle(navigationTitle)
      .task {
        await loadWorkspaceBootstrap()
      }
      .onAppear {
        syncExpandedProjects()
      }
      .onChange(of: store.projects.map(\.id)) { _, _ in
        syncExpandedProjects()
      }
      .onChange(of: store.selectedProjectID) { _, newValue in
        guard let newValue else { return }
        expandedProjectIDs.insert(newValue)
      }
      .onDisappear {
        selectionTask?.cancel()
      }
      .sheet(item: $activeSheet) { sheet in
        switch sheet {
        case let .renameSession(sessionID, currentTitle):
          MacRenameSessionSheet(sessionID: sessionID, currentTitle: currentTitle)
        }
      }
      .fileImporter(
        isPresented: $isProjectPickerPresented,
        allowedContentTypes: [.folder],
        allowsMultipleSelection: false,
        onCompletion: handleProjectDirectoryPick
      )
      .confirmationDialog("Delete Session?", isPresented: isDeleteConfirmationDialogPresented) {
        Button("Delete", role: .destructive) {
          deletePendingSession()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("This permanently removes the selected chat session.")
      }
      .toolbar {
        MacWorkspaceToolbar(
          selectedPanel: $selectedPanel,
          isPanelSelectionEnabled: selectedSessionID != nil,
          isRefreshingSessions: store.isRefreshingSessions,
          isCreatingSession: store.isCreatingSession,
          refreshSessions: refreshSessions,
          createSession: createSession
        )
      }
    }

    private var selectedSessionBinding: Binding<MacWorkspaceSidebarSelection?> {
      Binding(
        get: {
          sidebarSelection(for: store.selectedSessionID)
        },
        set: { selection in
          selectionTask?.cancel()
          selectionTask = Task {
            guard !Task.isCancelled else { return }
            await store.selectSession(selection?.sessionID)
          }
        }
      )
    }

    private func sidebarSelection(for sessionID: String?) -> MacWorkspaceSidebarSelection? {
      guard let sessionID else {
        return nil
      }

      if store.isSessionPinned(sessionID) {
        return .pinned(sessionID: sessionID)
      }

      guard let session = store.sessions.first(where: { $0.id == sessionID }) else {
        return nil
      }

      guard let project = store.projects.first(where: { $0.directory == session.directory }) else {
        return nil
      }

      return .thread(projectID: project.id, sessionID: sessionID)
    }

    private var isDeleteConfirmationDialogPresented: Binding<Bool> {
      Binding(
        get: { pendingDeleteSessionID != nil },
        set: { isPresented in
          if !isPresented {
            pendingDeleteSessionID = nil
          }
        }
      )
    }

    private func selectProjectFromSidebar(_ projectID: String) {
      store.selectProject(projectID)
      expandedProjectIDs.insert(projectID)
    }

    private func syncExpandedProjects() {
      let validProjectIDs = Set(store.projects.map(\.id))
      expandedProjectIDs = expandedProjectIDs.intersection(validProjectIDs)

      if expandedProjectIDs.isEmpty {
        if let selectedProjectID = store.selectedProjectID {
          expandedProjectIDs.insert(selectedProjectID)
        } else if let firstProjectID = store.projects.first?.id {
          expandedProjectIDs.insert(firstProjectID)
        }
      }
    }

    private func loadWorkspaceBootstrap() async {
      bootstrapState = .loading

      await store.refreshAgentAndModelOptions()
      await store.refreshSessions()

      if let error = store.latestConnectionError, !error.isEmpty, store.sessions.isEmpty {
        bootstrapState = .failed(error)
        return
      }

      bootstrapState = .ready
    }

    private func refreshSessions() {
      Task {
        await store.refreshSessions()
      }
    }

    private func createSession() {
      Task {
        await store.createSession()
      }
    }

    private func retryBootstrap() {
      Task {
        await loadWorkspaceBootstrap()
      }
    }

    private func presentProjectPicker() {
      isProjectPickerPresented = true
    }

    private func handleProjectDirectoryPick(_ result: Result<[URL], Error>) {
      guard case let .success(urls) = result, let directoryURL = urls.first else {
        return
      }

      guard store.addProject(directory: directoryURL.standardizedFileURL.path) else {
        return
      }

      Task {
        await store.refreshAgentAndModelOptions()
        await store.refreshSessions()
      }
    }

    private func prepareRenameSession(_ sessionID: String) {
      activeSheet = .renameSession(
        sessionID: sessionID,
        currentTitle: store.sessionTitle(for: sessionID)
      )
    }

    private func archiveSession(_ sessionID: String) {
      Task {
        await store.archiveSession(sessionID: sessionID)
      }
    }

    private func togglePinSession(_ sessionID: String) {
      store.togglePinnedSession(sessionID)
    }

    private func confirmDeleteSession(_ sessionID: String) {
      pendingDeleteSessionID = sessionID
    }

    private func deletePendingSession() {
      guard let sessionID = pendingDeleteSessionID else { return }
      pendingDeleteSessionID = nil

      Task {
        await store.deleteSession(sessionID: sessionID)
      }
    }
  }

  #Preview("Workspace Shell") {
    MacWorkspaceNavigationShell()
      .withMacWorkspacePreviewEnv()
      .frame(minWidth: 1200, minHeight: 760)
  }
#endif
