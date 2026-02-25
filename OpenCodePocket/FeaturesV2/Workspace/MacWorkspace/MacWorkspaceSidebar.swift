#if os(macOS)
  import OpenCodeModels
  import SwiftUI

  struct MacWorkspaceSidebar: View {
    @Environment(WorkspaceStore.self) private var store

    @Binding var selectedSessionID: String?
    @Binding var expandedProjectIDs: Set<String>
    let onSelectProject: (String) -> Void
    let onPresentProjectPicker: () -> Void

    var body: some View {
      List(selection: $selectedSessionID) {
        Section {
          ForEach(store.projects) { project in
            MacSidebarProjectSection(
              project: project,
              isExpanded: projectExpansionBinding(for: project.id)
            ) {
              onSelectProject(project.id)
            }
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
              onPresentProjectPicker()
            }
            .accessibilityIdentifier("projects.add.empty")
          }
        }
      }
    }

    private var threadsHeader: some View {
      HStack(spacing: 8) {
        Text("Threads")

        Spacer(minLength: 0)

        Button {
          onPresentProjectPicker()
        } label: {
          Image(systemName: "folder.badge.plus")
        }
        .buttonStyle(.borderless)
        .help("Add Project")
        .accessibilityIdentifier("projects.add")
      }
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
        Button(action: onSelectProject) {
          Label(project.name, systemImage: "folder")
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
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
      .tag(session.id as String?)
      .accessibilityIdentifier("sidebar.session.\(session.id)")
    }
  }

  #Preview("Sidebar - Projects") {
    MacWorkspaceSidebarPreviewHost()
      .withMacWorkspacePreviewEnv()
      .frame(width: 340, height: 760)
  }

  #Preview("Sidebar - Empty") {
    MacWorkspaceSidebarPreviewHost()
      .withMacWorkspacePreviewEnv(.emptyProjects)
      .frame(width: 340, height: 760)
  }

  private struct MacWorkspaceSidebarPreviewHost: View {
    @State private var selectedSessionID: String?
    @State private var expandedProjectIDs: Set<String> = []

    var body: some View {
      MacWorkspaceSidebar(
        selectedSessionID: $selectedSessionID,
        expandedProjectIDs: $expandedProjectIDs,
        onSelectProject: { _ in },
        onPresentProjectPicker: {}
      )
    }
  }
#endif
