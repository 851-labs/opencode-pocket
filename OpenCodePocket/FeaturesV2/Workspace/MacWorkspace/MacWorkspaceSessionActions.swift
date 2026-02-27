#if os(macOS)
  import SwiftUI

  struct MacWorkspaceToolbar: ToolbarContent {
    @Binding var selectedPanel: MacWorkspacePanel
    let isPanelSelectionEnabled: Bool
    let isRefreshingSessions: Bool
    let isCreatingSession: Bool
    let addProject: () -> Void
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

        Button(action: addProject) {
          Image(systemName: "folder.badge.plus")
        }
        .accessibilityIdentifier("projects.add")
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
#endif
