import OpenCodeModels
import SwiftUI

#if os(iOS)

  struct SessionSheet: View {
    @Environment(WorkspaceStore.self) private var store
    @Binding var isPresented: Bool

    @State private var isAddProjectPromptPresented = false
    @State private var projectDirectoryDraft = ""

    var body: some View {
      NavigationStack {
        List {
          actionsSection
          projectSections
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sessions")
        .alert("Add Project", isPresented: $isAddProjectPromptPresented, actions: addProjectAlertActions) {
          Text("Enter a directory path to add a project.")
        }
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
              isPresented = false
            }
          }
        }
        .accessibilityIdentifier("workspace.drawer")
      }
    }

    @ViewBuilder
    private var actionsSection: some View {
      Section("Actions") {
        Button {
          Task {
            await store.refreshSessions()
          }
        } label: {
          Label("Refresh", systemImage: "arrow.clockwise")
        }
        .accessibilityIdentifier("drawer.refresh")

        Button {
          store.beginNewSession()
          isPresented = false
        } label: {
          Label("New Session", systemImage: "plus")
        }
        .accessibilityIdentifier("drawer.create")

        Button {
          projectDirectoryDraft = ""
          isAddProjectPromptPresented = true
        } label: {
          Label("Add Project", systemImage: "folder.badge.plus")
        }
        .accessibilityIdentifier("drawer.project.add")
      }
    }

    @ViewBuilder
    private var projectSections: some View {
      ForEach(store.projects) { project in
        SessionSheetProjectSection(isPresented: $isPresented, project: project)
      }
    }

    @ViewBuilder
    private func addProjectAlertActions() -> some View {
      TextField("/path/to/project", text: $projectDirectoryDraft)

      Button("Cancel", role: .cancel) {
        projectDirectoryDraft = ""
      }

      Button("Add") {
        guard store.addProject(directory: projectDirectoryDraft) else {
          return
        }
        Task {
          await store.refreshAgentAndModelOptions()
          await store.refreshSessions()
        }
        projectDirectoryDraft = ""
      }
    }
  }

  private struct SessionSheetProjectSection: View {
    @Environment(WorkspaceStore.self) private var store
    @Binding var isPresented: Bool
    let project: SavedProject

    private var sessions: [Session] {
      store.visibleSessions(for: project.id)
    }

    var body: some View {
      Section(project.name) {
        Button {
          store.selectProject(project.id)
          isPresented = false
        } label: {
          Label(project.directory, systemImage: store.selectedProjectID == project.id ? "folder.fill" : "folder")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("drawer.project.\(project.id)")

        ForEach(sessions) { session in
          SessionSheetSessionRow(isPresented: $isPresented, session: session)
        }

        if sessions.isEmpty {
          Text("No sessions yet")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private struct SessionSheetSessionRow: View {
    @Environment(WorkspaceStore.self) private var store
    @Binding var isPresented: Bool
    let session: Session

    var body: some View {
      Button {
        Task {
          await store.selectSession(session.id)
          isPresented = false
        }
      } label: {
        HStack(spacing: 10) {
          VStack(alignment: .leading, spacing: 4) {
            Text(session.title)
              .font(.subheadline.weight(.semibold))
              .lineLimit(1)

            HStack(spacing: 6) {
              Text(session.id)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.secondary)

              Circle()
                .fill(Color.secondary.opacity(0.6))
                .frame(width: 3, height: 3)

              Text(store.statusLabel(for: session.id))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }

          Spacer()

          if store.selectedSessionID == session.id {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.tint)
          }
        }
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("drawer.session.\(session.id)")
    }
  }

#endif
