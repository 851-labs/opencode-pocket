#if os(macOS)
  import SwiftUI

  struct MacWorkspaceToolbar: ToolbarContent {
    @Binding var selectedPanel: MacWorkspacePanel
    let isPanelSelectionEnabled: Bool
    let isRefreshingSessions: Bool
    let isCreatingSession: Bool
    let refreshSessions: () -> Void
    let createSession: () -> Void

    @ToolbarContentBuilder
    var body: some ToolbarContent {
      ToolbarItem(placement: .principal) {
        Picker("Panel", selection: $selectedPanel) {
          ForEach(MacWorkspacePanel.allCases) { panel in
            Text(panel.rawValue).tag(panel)
          }
        }
        .pickerStyle(.segmented)
        .disabled(!isPanelSelectionEnabled)
      }

      ToolbarItemGroup {
        Button(action: refreshSessions) {
          if isRefreshingSessions {
            ProgressView()
              .controlSize(.small)
          } else {
            Image(systemName: "arrow.clockwise")
          }
        }
        .disabled(isRefreshingSessions)
        .accessibilityIdentifier("sessions.refresh")

        Button(action: createSession) {
          if isCreatingSession {
            ProgressView()
              .controlSize(.small)
          } else {
            Image(systemName: "plus")
          }
        }
        .disabled(isCreatingSession)
        .accessibilityIdentifier("sessions.create")
      }
    }
  }

  struct MacRenameSessionSheet: View {
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

  struct MacRenameProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkspaceStore.self) private var store

    let projectID: String

    @State private var name: String

    init(projectID: String, currentName: String) {
      self.projectID = projectID
      _name = State(initialValue: currentName)
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 14) {
        Text("Rename Project")
          .font(.headline)

        TextField("Project name", text: $name)

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
      store.renameProject(projectID: projectID, name: name)
      dismiss()
    }
  }
#endif
