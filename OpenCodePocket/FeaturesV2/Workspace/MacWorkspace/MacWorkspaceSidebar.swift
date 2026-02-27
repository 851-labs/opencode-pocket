#if os(macOS)
  import OpenCodeModels
  import SwiftUI

  enum MacWorkspaceSidebarSelection: Hashable {
    case pinned(sessionID: String)
    case thread(projectID: String, sessionID: String)

    var sessionID: String {
      switch self {
      case let .pinned(sessionID), let .thread(_, sessionID):
        return sessionID
      }
    }
  }

  struct MacWorkspaceSidebar: View {
    @Environment(MacWorkspaceRouterPath.self) private var routerPath
    @Environment(WorkspaceStore.self) private var store

    @Binding var selectedSession: MacWorkspaceSidebarSelection?
    @Binding var expandedProjectIDs: Set<String>
    let onSelectProject: (String) -> Void
    let onTogglePinSession: (String) -> Void
    let onCreateSessionInProject: (String) -> Void

    private var pinnedRows: [MacSidebarSessionListRow] {
      store.pinnedSessions.map {
        MacSidebarSessionListRow(
          selection: .pinned(sessionID: $0.id),
          session: $0
        )
      }
    }

    var body: some View {
      List(selection: $selectedSession) {
        if !store.pinnedSessions.isEmpty {
          Section("Pins") {
            ForEach(pinnedRows) { row in
              MacSidebarSessionRow(
                row: row,
                onTogglePinSession: onTogglePinSession
              )
            }
          }
        }

        Section {
          ForEach(store.projects) { project in
            MacSidebarProjectSection(
              project: project,
              isExpanded: projectExpansionBinding(for: project.id),
              onSelectProject: {
                onSelectProject(project.id)
              },
              onTogglePinSession: onTogglePinSession,
              onCreateSessionInProject: onCreateSessionInProject
            )
          }
        } header: {
          threadsHeader
        }
      }
      .navigationTitle("Sessions")
      .overlay {
        if store.projects.isEmpty {
          ContentUnavailableView {
            Label("No Projects", systemImage: "folder.badge.plus")
          } description: {
            Text("Add a project directory to start browsing sessions.")
          } actions: {
            Button("Add Project") {
              routerPath.isProjectPickerPresented = true
            }
            .accessibilityIdentifier("projects.add.empty")
          }
        }
      }
    }

    private var threadsHeader: some View {
      Text("Threads")
        .textCase(nil)
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
  }

  private struct MacSidebarProjectSection: View {
    @Environment(MacWorkspaceRouterPath.self) private var routerPath
    @Environment(WorkspaceStore.self) private var store

    let project: SavedProject
    @Binding var isExpanded: Bool
    let onSelectProject: () -> Void
    let onTogglePinSession: (String) -> Void
    let onCreateSessionInProject: (String) -> Void

    private var sessions: [Session] {
      store.visibleSessions(for: project.id)
        .filter { !store.isSessionPinned($0.id) }
    }

    private var rows: [MacSidebarSessionListRow] {
      sessions.map {
        MacSidebarSessionListRow(
          selection: .thread(projectID: project.id, sessionID: $0.id),
          session: $0
        )
      }
    }

    private var projectSymbol: String {
      project.symbol?.trimmedNonEmpty ?? "folder"
    }

    var body: some View {
      DisclosureGroup(isExpanded: $isExpanded) {
        if sessions.isEmpty {
          Text("No threads yet")
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
          ForEach(rows) { row in
            MacSidebarSessionRow(
              row: row,
              onTogglePinSession: onTogglePinSession
            )
          }
        }
      } label: {
        Button(action: onSelectProject) {
          Label(project.name, systemImage: projectSymbol)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .contextMenu {
          Button {
            onCreateSessionInProject(project.id)
          } label: {
            Label("New Session", systemImage: "plus")
          }

          Button {
            routerPath.presentedSheet = .renameProject(projectID: project.id, currentName: project.name)
          } label: {
            Label("Rename", systemImage: "pencil")
          }

          Button {
            routerPath.presentedSheet = .customizeProject(
              projectID: project.id,
              currentName: project.name,
              currentSymbol: project.symbol
            )
          } label: {
            Label("Customize", systemImage: "paintbrush")
          }

          Button(role: .destructive) {
            routerPath.pendingRemoveProjectID = project.id
          } label: {
            Label("Remove", systemImage: "trash")
          }
        }
      }
      .accessibilityIdentifier("sidebar.project.\(project.id)")
    }
  }

  private struct MacSidebarSessionListRow: Identifiable {
    let selection: MacWorkspaceSidebarSelection
    let session: Session

    var id: MacWorkspaceSidebarSelection {
      selection
    }
  }

  private struct MacSidebarSessionRow: View {
    @Environment(MacWorkspaceRouterPath.self) private var routerPath
    @Environment(WorkspaceStore.self) private var store

    let row: MacSidebarSessionListRow
    let onTogglePinSession: (String) -> Void

    private static let elapsedFormatter: DateComponentsFormatter = {
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.weekOfMonth, .day, .hour, .minute]
      formatter.unitsStyle = .abbreviated
      formatter.maximumUnitCount = 1
      formatter.zeroFormattingBehavior = .dropAll
      return formatter
    }()

    private var elapsedSinceLastActivity: String {
      guard let raw = row.session.time.updated ?? row.session.time.created else {
        return "now"
      }

      let seconds = raw > 10_000_000_000 ? raw / 1000 : raw
      let interval = max(0, Date().timeIntervalSince1970 - seconds)
      guard interval >= 60 else {
        return "now"
      }

      return Self.elapsedFormatter.string(from: interval) ?? "now"
    }

    private var isPinnedRow: Bool {
      if case .pinned = row.selection {
        return true
      }
      return false
    }

    var body: some View {
      sessionRowContent
        .tag(row.selection as MacWorkspaceSidebarSelection?)
        .contextMenu {
          if store.isSessionPinned(row.session.id) {
            Button {
              onTogglePinSession(row.session.id)
            } label: {
              Label("Unpin", systemImage: "pin.slash")
            }
          } else {
            Button {
              onTogglePinSession(row.session.id)
            } label: {
              Label("Pin", systemImage: "pin")
            }
          }

          Button {
            routerPath.presentedSheet = .renameSession(
              sessionID: row.session.id,
              currentTitle: store.sessionTitle(for: row.session.id)
            )
          } label: {
            Label("Rename", systemImage: "pencil")
          }

          Button {
            routerPath.pendingArchiveSessionID = row.session.id
          } label: {
            Label("Archive", systemImage: "archivebox")
          }

          Button(role: .destructive) {
            routerPath.pendingDeleteSessionID = row.session.id
          } label: {
            Label("Delete", systemImage: "trash")
          }
        }
        .accessibilityIdentifier("sidebar.session.\(row.session.id)")
    }

    private var sessionRowContent: some View {
      LabeledContent {
        Text(elapsedSinceLastActivity)
      } label: {
        Label {
          Text(row.session.title)
        } icon: {
          if store.status(for: row.session.id).isRunning {
            ProgressView()
              .controlSize(.small)
          } else if isPinnedRow {
            Image(systemName: "pin.fill")
              .foregroundStyle(.secondary)
          } else {
            Image(systemName: "circle.fill")
              .hidden()
          }
        }
      }
    }
  }

  #Preview("Sidebar - Projects") {
    MacWorkspaceSidebarPreviewHost()
      .withMacWorkspacePreviewEnv()
      .frame(width: 340, height: 760)
  }

  #Preview("Sidebar - Pinned") {
    MacWorkspaceSidebarPreviewHost()
      .withMacWorkspacePreviewEnv(.pinnedThreads)
      .frame(width: 340, height: 760)
  }

  #Preview("Sidebar - Empty") {
    MacWorkspaceSidebarPreviewHost()
      .withMacWorkspacePreviewEnv(.emptyProjects)
      .frame(width: 340, height: 760)
  }

  private struct MacWorkspaceSidebarPreviewHost: View {
    @State private var selectedSession: MacWorkspaceSidebarSelection?
    @State private var expandedProjectIDs: Set<String> = []

    var body: some View {
      MacWorkspaceSidebar(
        selectedSession: $selectedSession,
        expandedProjectIDs: $expandedProjectIDs,
        onSelectProject: { _ in },
        onTogglePinSession: { _ in },
        onCreateSessionInProject: { _ in }
      )
      .environment(MacWorkspaceRouterPath())
    }
  }
#endif
