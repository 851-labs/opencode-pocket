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
    @State private var isDeleteConfirmationPresented = false
    @State private var expandedProjectIDs: Set<String> = []

    private var selectedSessionID: String? {
      store.selectedSessionID
    }

    var body: some View {
      NavigationSplitView {
        MacWorkspaceSidebar(
          selectedSessionID: selectedSessionBinding,
          expandedProjectIDs: $expandedProjectIDs,
          onSelectProject: selectProjectFromSidebar,
          onPresentProjectPicker: presentProjectPicker
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
      .task {
        await loadWorkspaceBootstrap()
      }
      .onAppear {
        syncExpandedProjects()
      }
      .onChange(of: store.selectedSessionID) { _, newValue in
        Task {
          await store.selectSession(newValue)
        }
      }
      .onChange(of: store.projects.map(\.id)) { _, _ in
        syncExpandedProjects()
      }
      .onChange(of: store.selectedProjectID) { _, newValue in
        guard let newValue else { return }
        expandedProjectIDs.insert(newValue)
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
      .confirmationDialog("Delete Session?", isPresented: $isDeleteConfirmationPresented) {
        Button("Delete", role: .destructive) {
          deleteSelectedSession()
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("This permanently removes the selected chat session.")
      }
      .toolbar {
        MacWorkspaceToolbar(
          isRefreshingSessions: store.isRefreshingSessions,
          isCreatingSession: store.isCreatingSession,
          hasSelectedSession: selectedSessionID != nil,
          refreshSessions: refreshSessions,
          createSession: createSession,
          renameSelectedSession: prepareRenameSession,
          archiveSelectedSession: archiveSelectedSession,
          confirmDeleteSelectedSession: confirmDeleteSelectedSession
        )
      }
    }

    private var selectedSessionBinding: Binding<String?> {
      Binding(
        get: { store.selectedSessionID },
        set: { store.selectedSessionID = $0 }
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

    private func confirmDeleteSelectedSession() {
      guard selectedSessionID != nil else { return }
      isDeleteConfirmationPresented = true
    }

    private func deleteSelectedSession() {
      guard let selectedSessionID else { return }
      Task {
        await store.deleteSession(sessionID: selectedSessionID)
      }
    }
  }

  #Preview("Workspace Shell") {
    MacWorkspaceNavigationShell()
      .withMacWorkspacePreviewEnv()
      .frame(minWidth: 1200, minHeight: 760)
  }
#endif
