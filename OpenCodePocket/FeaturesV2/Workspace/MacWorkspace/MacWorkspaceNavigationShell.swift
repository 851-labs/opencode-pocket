#if os(macOS)
  import Observation
  import SwiftUI
  import UniformTypeIdentifiers

  enum MacWorkspacePanel: String, CaseIterable, Identifiable {
    case transcript = "Transcript"
    case changes = "Changes"

    var id: Self { self }
  }

  enum MacWorkspaceSheetDestination: Identifiable {
    case customizeProject(projectID: String, currentName: String, currentSymbol: String?)

    var id: String {
      switch self {
      case let .customizeProject(projectID, _, _):
        return "customize-project-\(projectID)"
      }
    }
  }

  @MainActor
  @Observable
  final class MacWorkspaceRouterPath {
    var presentedSheet: MacWorkspaceSheetDestination?
    var isProjectPickerPresented = false
    var pendingArchiveSessionID: String?
    var pendingDeleteSessionID: String?
    var pendingRemoveProjectID: String?
    var pendingRenameSessionID: String?
    var pendingRenameProjectID: String?
  }

  enum MacWorkspaceBootstrapState {
    case loading
    case ready
    case failed(String)
  }

  private extension MacWorkspaceBootstrapState {
    var workspaceSessionInspectorState: WorkspaceSessionInspectorBootstrapState {
      switch self {
      case .loading:
        return .loading
      case .ready:
        return .ready
      case let .failed(message):
        return .failed(message)
      }
    }
  }

  struct MacWorkspaceNavigationShell: View {
    @Environment(WorkspaceStore.self) private var store

    @State private var selectedPanel: MacWorkspacePanel = .transcript
    @State private var bootstrapState: MacWorkspaceBootstrapState = .loading
    @State private var routerPath = MacWorkspaceRouterPath()
    @State private var expandedProjectIDs: Set<String> = []
    @State private var selectionTask: Task<Void, Never>?
    @State private var renameSessionTitleDraft = ""
    @State private var renameSessionTextFieldID = UUID()
    @State private var renameProjectNameDraft = ""
    @State private var renameProjectTextFieldID = UUID()
    @State private var isInspectorVisible = true

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
      @Bindable var routerPath = routerPath

      NavigationSplitView {
        MacWorkspaceSidebar(
          selectedSession: selectedSessionBinding,
          expandedProjectIDs: $expandedProjectIDs,
          onSelectProject: selectProjectFromSidebar,
          onTogglePinSession: togglePinSession,
          onCreateSessionInProject: createSessionInProject,
          onRequestSessionRename: presentSessionRenameAlert,
          onRequestProjectRename: presentProjectRenameAlert
        )
        .toolbar {
          MacWorkspaceSidebarToolbar(
            isRefreshingSessions: store.isRefreshingSessions,
            refreshSessions: refreshSessions,
            presentProjectPicker: presentProjectPicker
          )
        }
      } detail: {
        MacWorkspaceDetail(
          bootstrapState: bootstrapState,
          selectedSessionID: selectedSessionID,
          selectedPanel: $selectedPanel,
          retry: retryBootstrap
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inspector(isPresented: $isInspectorVisible) {
          WorkspaceSessionInspector(
            bootstrapState: bootstrapState.workspaceSessionInspectorState,
            selectedSessionID: selectedSessionID
          )
          .inspectorColumnWidth(min: 280, ideal: 320, max: 380)
        }
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
      .sheet(item: $routerPath.presentedSheet) { sheet in
        switch sheet {
        case let .customizeProject(projectID, currentName, currentSymbol):
          MacCustomizeProjectSheet(projectID: projectID, currentName: currentName, currentSymbol: currentSymbol)
        }
      }
      .renameSessionAlert(
        isPresented: isRenameSessionAlertPresented,
        title: $renameSessionTitleDraft,
        textFieldID: renameSessionTextFieldID,
        onSave: savePendingSessionRename
      )
      .renameProjectAlert(
        isPresented: isRenameProjectAlertPresented,
        name: $renameProjectNameDraft,
        textFieldID: renameProjectTextFieldID,
        onSave: savePendingProjectRename
      )
      .fileImporter(
        isPresented: $routerPath.isProjectPickerPresented,
        allowedContentTypes: [.folder],
        allowsMultipleSelection: false,
        onCompletion: handleProjectDirectoryPick
      )
      .archiveSessionConfirmationDialog(
        isPresented: isArchiveConfirmationDialogPresented,
        onArchive: archivePendingSession
      )
      .deleteSessionConfirmationDialog(
        isPresented: isDeleteConfirmationDialogPresented,
        onDelete: deletePendingSession
      )
      .removeProjectConfirmationDialog(
        isPresented: isRemoveProjectConfirmationDialogPresented,
        onRemove: removePendingProject
      )
      .toolbar {
        MacWorkspaceToolbar(
          selectedPanel: $selectedPanel,
          isInspectorVisible: $isInspectorVisible,
          isPanelSelectionEnabled: selectedSessionID != nil
        )
      }
      .environment(routerPath)
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
        get: { routerPath.pendingDeleteSessionID != nil },
        set: { isPresented in
          if !isPresented {
            routerPath.pendingDeleteSessionID = nil
          }
        }
      )
    }

    private var isArchiveConfirmationDialogPresented: Binding<Bool> {
      Binding(
        get: { routerPath.pendingArchiveSessionID != nil },
        set: { isPresented in
          if !isPresented {
            routerPath.pendingArchiveSessionID = nil
          }
        }
      )
    }

    private var isRemoveProjectConfirmationDialogPresented: Binding<Bool> {
      Binding(
        get: { routerPath.pendingRemoveProjectID != nil },
        set: { isPresented in
          if !isPresented {
            routerPath.pendingRemoveProjectID = nil
          }
        }
      )
    }

    private var isRenameSessionAlertPresented: Binding<Bool> {
      Binding(
        get: { routerPath.pendingRenameSessionID != nil },
        set: { isPresented in
          if !isPresented {
            routerPath.pendingRenameSessionID = nil
          }
        }
      )
    }

    private var isRenameProjectAlertPresented: Binding<Bool> {
      Binding(
        get: { routerPath.pendingRenameProjectID != nil },
        set: { isPresented in
          if !isPresented {
            routerPath.pendingRenameProjectID = nil
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
      await store.refreshInspectorServices()

      if let error = store.latestError, !error.isEmpty, store.sessions.isEmpty {
        bootstrapState = .failed(error)
        return
      }

      bootstrapState = .ready
    }

    private func refreshSessions() {
      Task {
        await store.refreshSessions()
        await store.refreshInspectorServices()
      }
    }

    private func createSessionInProject(_ projectID: String) {
      Task {
        await store.createSession(inProjectID: projectID)
      }
    }

    private func presentSessionRenameAlert(sessionID: String, currentTitle: String) {
      renameSessionTitleDraft = currentTitle
      renameSessionTextFieldID = UUID()
      routerPath.pendingRenameSessionID = sessionID
    }

    private func presentProjectRenameAlert(projectID: String, currentName: String) {
      renameProjectNameDraft = currentName
      renameProjectTextFieldID = UUID()
      routerPath.pendingRenameProjectID = projectID
    }

    private func presentProjectPicker() {
      routerPath.isProjectPickerPresented = true
    }

    private func retryBootstrap() {
      Task {
        await loadWorkspaceBootstrap()
      }
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
        await store.refreshInspectorServices()
      }
    }

    private func archivePendingSession() {
      guard let sessionID = routerPath.pendingArchiveSessionID else { return }
      routerPath.pendingArchiveSessionID = nil

      Task {
        await store.archiveSession(sessionID: sessionID)
      }
    }

    private func togglePinSession(_ sessionID: String) {
      store.togglePinnedSession(sessionID)
    }

    private func deletePendingSession() {
      guard let sessionID = routerPath.pendingDeleteSessionID else { return }
      routerPath.pendingDeleteSessionID = nil

      Task {
        await store.deleteSession(sessionID: sessionID)
      }
    }

    private func removePendingProject() {
      guard let projectID = routerPath.pendingRemoveProjectID else { return }
      routerPath.pendingRemoveProjectID = nil
      _ = store.removeProject(projectID: projectID)
    }

    private func savePendingSessionRename() {
      guard let sessionID = routerPath.pendingRenameSessionID else { return }
      let title = renameSessionTitleDraft
      routerPath.pendingRenameSessionID = nil

      Task {
        await store.renameSession(sessionID: sessionID, title: title)
      }
    }

    private func savePendingProjectRename() {
      guard let projectID = routerPath.pendingRenameProjectID else { return }
      store.renameProject(projectID: projectID, name: renameProjectNameDraft)
      routerPath.pendingRenameProjectID = nil
    }
  }

  #Preview("Workspace Shell") {
    MacWorkspaceNavigationShell()
      .withMacWorkspacePreviewEnv()
      .frame(minWidth: 1200, minHeight: 760)
  }
#endif
