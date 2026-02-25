#if os(macOS)
  import OpenCodeModels
  import SwiftUI
  import UniformTypeIdentifiers

  private enum MacWorkspacePanel: String, CaseIterable, Identifiable {
    case transcript = "Transcript"
    case changes = "Changes"

    var id: Self { self }
  }

  private enum MacWorkspaceSheet: Identifiable {
    case renameSession(sessionID: String, currentTitle: String)

    var id: String {
      switch self {
      case let .renameSession(sessionID, _):
        return "rename-\(sessionID)"
      }
    }
  }

  private enum MacWorkspaceBootstrapState {
    case loading
    case ready
    case failed(String)
  }

  struct MacWorkspaceView: View {
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
        toolbarContent
      }
    }

    private var sidebar: some View {
      @Bindable var store = store

      return List(selection: $store.selectedSessionID) {
        Section("Threads") {
          ForEach(store.projects) { project in
            MacSidebarProjectSection(
              project: project,
              isExpanded: projectExpansionBinding(for: project.id)
            ) {
              selectProjectFromSidebar(project.id)
            }
          }
        }
      }
      .navigationTitle("Sessions")
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
          isProjectPickerPresented = true
        } label: {
          Image(systemName: "folder.badge.plus")
        }
        .accessibilityIdentifier("projects.add")
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

    private func projectExpansionBinding(for projectID: String) -> Binding<Bool> {
      Binding(
        get: {
          expandedProjectIDs.contains(projectID)
        },
        set: { isExpanded in
          if isExpanded {
            expandedProjectIDs.insert(projectID)
          } else {
            expandedProjectIDs.remove(projectID)
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

    private func deleteSelectedSession() {
      guard let selectedSessionID else { return }
      Task {
        await store.deleteSession(sessionID: selectedSessionID)
      }
    }
  }

  private struct MacSidebarProjectSection: View {
    @Environment(WorkspaceStore.self) private var store
    let project: SavedProject
    @Binding var isExpanded: Bool
    let onSelectProject: () -> Void

    private var sessions: [Session] {
      store.visibleSessions(for: project.id)
    }

    var body: some View {
      DisclosureGroup(isExpanded: $isExpanded) {
        if sessions.isEmpty {
          Text("No threads yet")
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
          ForEach(sessions) { session in
            MacSidebarSessionRow(session: session)
          }
        }
      } label: {
        Label(project.name, systemImage: "folder")
          .onTapGesture {
            onSelectProject()
          }
      }
      .accessibilityIdentifier("sidebar.project.\(project.id)")
    }
  }

  private struct MacSidebarSessionRow: View {
    @Environment(WorkspaceStore.self) private var store
    let session: Session

    private static let elapsedFormatter: DateComponentsFormatter = {
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.weekOfMonth, .day, .hour, .minute]
      formatter.unitsStyle = .abbreviated
      formatter.maximumUnitCount = 1
      formatter.zeroFormattingBehavior = .dropAll
      return formatter
    }()

    private var elapsedSinceLastActivity: String {
      guard let raw = session.time.updated ?? session.time.created else {
        return "now"
      }

      let seconds = raw > 10_000_000_000 ? raw / 1000 : raw
      let interval = max(0, Date().timeIntervalSince1970 - seconds)
      guard interval >= 60 else {
        return "now"
      }

      return Self.elapsedFormatter.string(from: interval) ?? "now"
    }

    var body: some View {
      LabeledContent {
        Text(elapsedSinceLastActivity)
      } label: {
        Label {
          Text(session.title)
        } icon: {
          if store.status(for: session.id).isRunning {
            ProgressView()
              .controlSize(.small)
          } else {
            Image(systemName: "circle.fill")
              .hidden()
          }
        }
      }
      .onTapGesture {
        store.selectedSessionID = session.id
      }
      .tag(session.id as String?)
      .accessibilityIdentifier("sidebar.session.\(session.id)")
    }
  }

  private struct MacWorkspaceDetailContent: View {
    @Environment(WorkspaceStore.self) private var store
    let selectedSessionID: String
    @Binding var selectedPanel: MacWorkspacePanel

    @State private var composerHeight: CGFloat = 0

    private var composerBottomInset: CGFloat {
      max(0, composerHeight + 8)
    }

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

        ZStack(alignment: .bottom) {
          Group {
            switch selectedPanel {
            case .transcript:
              MacTranscriptPane(
                messages: store.messagesBySession[selectedSessionID] ?? [],
                sessionStatus: store.status(for: selectedSessionID),
                showReasoningSummaries: store.showReasoningSummaries,
                expandShellToolParts: store.expandShellToolParts,
                expandEditToolParts: store.expandEditToolParts,
                bottomInset: composerBottomInset
              )
            case .changes:
              MacChangesPane(
                diffs: store.diffsBySession[selectedSessionID] ?? [],
                bottomInset: composerBottomInset
              )
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)

          MacComposerView(sessionID: selectedSessionID)
            .padding(12)
            .background {
              GeometryReader { proxy in
                Color.clear
                  .preference(key: MacComposerHeightPreferenceKey.self, value: proxy.size.height)
              }
            }
        }
        .onPreferenceChange(MacComposerHeightPreferenceKey.self) { value in
          composerHeight = value
        }
      }
    }
  }

  private struct MacComposerHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
      value = max(value, nextValue())
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
    @Environment(WorkspaceStore.self) private var store

    let sessionID: String

    @State private var title: String

    init(sessionID: String, currentTitle: String) {
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

  private struct MacChangesPane: View {
    let diffs: [FileDiff]
    let bottomInset: CGFloat

    var body: some View {
      if diffs.isEmpty {
        ContentUnavailableView(
          "No Code Changes",
          systemImage: "doc.text.magnifyingglass",
          description: Text("Run a coding task to populate this diff view.")
        )
      } else {
        List {
          ForEach(diffs) { diff in
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

          Color.clear
            .frame(height: max(0, bottomInset))
            .listRowInsets(.init())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.inset)
      }
    }
  }
#endif
