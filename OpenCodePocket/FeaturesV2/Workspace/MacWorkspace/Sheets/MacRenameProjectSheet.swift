#if os(macOS)
  import SwiftUI

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

  #Preview("Rename Project") {
    MacRenameProjectSheet(projectID: "project_preview", currentName: "Project name")
      .withMacWorkspacePreviewEnv()
      .frame(width: 380)
  }
#endif
