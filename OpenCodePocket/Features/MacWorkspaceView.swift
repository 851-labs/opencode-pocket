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

    @State private var selectedPanel: MacWorkspacePanel = .transcript
    @State private var bootstrapState: MacWorkspaceBootstrapState = .loading
    @State private var activeSheet: MacWorkspaceSheet?
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
        Section("Threads") {
          ForEach(store.projects) { project in
            MacSidebarProjectSection(
              store: store,
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
            MacSidebarSessionRow(store: store, session: session)
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
    @Bindable var store: WorkspaceStore
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
          if store.status(for: session.id).type == .idle {
            EmptyView()
          } else {
            ProgressView()
              .controlSize(.small)
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
    @Bindable var store: WorkspaceStore
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

          MacComposerView(store: store, sessionID: selectedSessionID)
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
    @State private var isServerBrowserPresented = false

    var body: some View {
      VStack(alignment: .leading, spacing: 14) {
        Text("Add Project")
          .font(.headline)

        HStack(spacing: 8) {
          TextField("/path/to/project", text: $directory)

          Button("Browse Server…") {
            isServerBrowserPresented = true
          }
          .accessibilityIdentifier("projects.browse.server")
        }

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
      .sheet(isPresented: $isServerBrowserPresented) {
        MacServerDirectoryBrowserSheet(store: store, initialDirectory: directory) { selectedDirectory in
          directory = selectedDirectory
        }
      }
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

  private struct MacServerDirectoryBrowserSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var store: WorkspaceStore
    let initialDirectory: String
    let onSelect: (String) -> Void

    @State private var rootDirectory = ""
    @State private var selectedDirectory: String?
    @State private var expandedDirectories: Set<String> = []
    @State private var childrenByDirectory: [String: [FileNode]] = [:]
    @State private var loadingDirectories: Set<String> = []

    @State private var searchQuery = ""
    @State private var searchResults: [String] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    @State private var isLoadingRoot = false
    @State private var errorMessage: String?

    private struct DirectoryRow: Identifiable {
      let path: String
      let depth: Int

      var id: String {
        path
      }
    }

    private var trimmedSearchQuery: String {
      searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var directoryRows: [DirectoryRow] {
      guard !rootDirectory.isEmpty else {
        return []
      }

      var rows: [DirectoryRow] = []
      appendDirectoryRows(path: rootDirectory, depth: 0, rows: &rows)
      return rows
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        Text("Browse Server")
          .font(.headline)

        TextField("Search directories", text: $searchQuery)
          .textFieldStyle(.roundedBorder)

        if let errorMessage, !errorMessage.isEmpty {
          Text(errorMessage)
            .font(.caption)
            .foregroundStyle(.red)
        }

        Group {
          if isLoadingRoot {
            ProgressView("Loading directories…")
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
          } else if !trimmedSearchQuery.isEmpty {
            searchResultsContent
          } else {
            treeContent
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.gray.opacity(0.08))
        )

        HStack(spacing: 10) {
          Text(selectedDirectory ?? rootDirectory)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)

          Spacer()

          Button("Cancel") {
            dismiss()
          }

          Button("Use Selected") {
            guard let selectedDirectory, let normalized = selectedDirectory.trimmedNonEmpty else {
              return
            }
            onSelect(normalized)
            dismiss()
          }
          .disabled((selectedDirectory ?? "").trimmedNonEmpty == nil)
          .keyboardShortcut(.defaultAction)
        }
      }
      .padding(18)
      .frame(width: 760, height: 560)
      .task {
        await loadRootDirectory()
      }
      .onChange(of: searchQuery) { _, _ in
        scheduleSearch()
      }
      .onDisappear {
        searchTask?.cancel()
      }
    }

    private var treeContent: some View {
      List(selection: $selectedDirectory) {
        ForEach(directoryRows) { row in
          directoryRowView(row)
            .tag(Optional(row.path))
        }
      }
      .listStyle(.inset)
      .accessibilityIdentifier("projects.server.browser.tree")
    }

    @ViewBuilder
    private var searchResultsContent: some View {
      if isSearching {
        ProgressView("Searching…")
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else if searchResults.isEmpty {
        ContentUnavailableView(
          "No Folders Found",
          systemImage: "magnifyingglass",
          description: Text("Try a different search query.")
        )
      } else {
        List(searchResults, id: \.self, selection: $selectedDirectory) { path in
          HStack(spacing: 8) {
            Image(systemName: "folder")
              .foregroundStyle(.secondary)
            Text(path)
              .lineLimit(1)
              .truncationMode(.middle)
          }
          .tag(Optional(path))
        }
        .listStyle(.inset)
        .accessibilityIdentifier("projects.server.browser.search")
      }
    }

    @ViewBuilder
    private func directoryRowView(_ row: DirectoryRow) -> some View {
      let isExpanded = expandedDirectories.contains(row.path)
      let isLoading = loadingDirectories.contains(row.path)

      HStack(spacing: 6) {
        Button {
          toggleExpansion(for: row.path)
        } label: {
          if isLoading {
            ProgressView()
              .controlSize(.mini)
              .frame(width: 12, height: 12)
          } else {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .frame(width: 12, height: 12)
          }
        }
        .buttonStyle(.plain)

        Image(systemName: "folder")
          .foregroundStyle(.secondary)

        Text(displayName(for: row.path))
          .lineLimit(1)

        Spacer(minLength: 0)
      }
      .padding(.leading, CGFloat(row.depth) * 14)
      .contentShape(Rectangle())
      .onTapGesture(count: 2) {
        selectedDirectory = row.path
        onSelect(row.path)
        dismiss()
      }
    }

    private func appendDirectoryRows(path: String, depth: Int, rows: inout [DirectoryRow]) {
      rows.append(DirectoryRow(path: path, depth: depth))
      guard expandedDirectories.contains(path), let children = childrenByDirectory[path] else {
        return
      }

      for child in children where child.type == .directory {
        appendDirectoryRows(path: child.absolute, depth: depth + 1, rows: &rows)
      }
    }

    private func toggleExpansion(for path: String) {
      if expandedDirectories.contains(path) {
        expandedDirectories.remove(path)
        return
      }

      expandedDirectories.insert(path)
      Task {
        await loadChildren(for: path)
      }
    }

    private func displayName(for path: String) -> String {
      if path == "/" {
        return "/"
      }
      return URL(fileURLWithPath: path).lastPathComponent
    }

    private func loadRootDirectory() async {
      guard rootDirectory.isEmpty else {
        return
      }

      isLoadingRoot = true
      defer {
        isLoadingRoot = false
      }

      do {
        let root = try await store.fetchServerBrowseRootDirectory()
        rootDirectory = root
        expandedDirectories.insert(root)

        if let selected = initialDirectory.trimmedNonEmpty {
          selectedDirectory = URL(fileURLWithPath: selected).standardizedFileURL.path
        } else {
          selectedDirectory = root
        }

        await loadChildren(for: root)
      } catch {
        errorMessage = error.localizedDescription
      }
    }

    private func loadChildren(for directory: String) async {
      if childrenByDirectory[directory] != nil || loadingDirectories.contains(directory) {
        return
      }

      loadingDirectories.insert(directory)
      defer {
        loadingDirectories.remove(directory)
      }

      do {
        let nodes = try await store.listServerDirectory(path: directory)
        childrenByDirectory[directory] = nodes.filter { $0.type == .directory }
      } catch {
        errorMessage = error.localizedDescription
      }
    }

    private func scheduleSearch() {
      searchTask?.cancel()
      let query = trimmedSearchQuery

      guard !query.isEmpty, !rootDirectory.isEmpty else {
        isSearching = false
        searchResults = []
        return
      }

      searchTask = Task { @MainActor in
        try? await Task.sleep(nanoseconds: 250_000_000)
        guard !Task.isCancelled else {
          return
        }

        isSearching = true
        defer {
          isSearching = false
        }

        do {
          searchResults = try await store.searchServerDirectories(path: rootDirectory, query: query)
        } catch {
          searchResults = []
          errorMessage = error.localizedDescription
        }
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
