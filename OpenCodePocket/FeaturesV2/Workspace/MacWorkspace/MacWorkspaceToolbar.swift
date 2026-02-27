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
#endif
