#if os(macOS)
import SwiftUI

struct MacWorkspaceSidebarToolbar: ToolbarContent {
  let isRefreshingSessions: Bool
  let refreshSessions: () -> Void
  let presentProjectPicker: () -> Void
  
  @ToolbarContentBuilder
  var body: some ToolbarContent {
    ToolbarItemGroup(placement: .automatic) {
      Button(action: refreshSessions) {
        Label {
          Text("Refresh")
        } icon: {
          if isRefreshingSessions {
            ProgressView()
              .controlSize(.small)
          } else {
            Image(systemName: "arrow.clockwise")
          }
        }
      }
      .disabled(isRefreshingSessions)
      .accessibilityIdentifier("sessions.refresh")
      .help("Refresh")
      
      Button(action: presentProjectPicker) {
        Label("Add Project", systemImage: "folder.badge.plus")
      }
      .accessibilityIdentifier("projects.add")
      .help("Add Project")
    }
  }
}
#endif
