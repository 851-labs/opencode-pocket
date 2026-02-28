#if os(macOS)
  import SwiftUI

  struct MacWorkspaceToolbar: ToolbarContent {
    @Binding var selectedPanel: MacWorkspacePanel
    @Binding var isInspectorVisible: Bool
    let isPanelSelectionEnabled: Bool
    let isRefreshingSessions: Bool
    let refreshSessions: () -> Void

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
        Button {
          isInspectorVisible.toggle()
        } label: {
          Image(systemName: "sidebar.right")
        }
        .accessibilityIdentifier("workspace.inspector.toggle")
        .accessibilityLabel(isInspectorVisible ? "Hide Inspector" : "Show Inspector")

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
      }
    }
  }
#endif
