#if os(macOS)
  import SwiftUI

  struct MacCustomizeProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkspaceStore.self) private var store

    let projectID: String
    let currentName: String

    @State private var symbolName: String

    private let presetSymbols = [
      "folder",
      "hammer",
      "shippingbox",
      "terminal",
      "doc.richtext",
      "tray.full",
      "bolt",
      "brain",
      "chart.bar",
      "camera",
      "gamecontroller",
      "puzzlepiece",
    ]

    init(projectID: String, currentName: String, currentSymbol: String?) {
      self.projectID = projectID
      self.currentName = currentName
      _symbolName = State(initialValue: currentSymbol ?? "")
    }

    private var previewSymbol: String {
      symbolName.trimmedNonEmpty ?? "folder"
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 14) {
        Text("Customize Project")
          .font(.headline)

        Label(currentName, systemImage: previewSymbol)
          .font(.title3)

        TextField("SF Symbol name", text: $symbolName)

        Text("Enter any SF Symbol name, or pick one below.")
          .font(.caption)
          .foregroundStyle(.secondary)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
          ForEach(presetSymbols, id: \.self) { symbol in
            Button {
              symbolName = symbol
            } label: {
              Image(systemName: symbol)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
          }
        }

        HStack {
          Button("Reset") {
            symbolName = ""
          }

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
      .frame(width: 420)
    }

    private func save() {
      store.setProjectSymbol(projectID: projectID, symbol: symbolName)
      dismiss()
    }
  }

  #Preview("Customize Project") {
    MacCustomizeProjectSheet(projectID: "project_preview", currentName: "Project name", currentSymbol: "hammer")
      .withMacWorkspacePreviewEnv()
      .frame(width: 440)
  }
#endif
