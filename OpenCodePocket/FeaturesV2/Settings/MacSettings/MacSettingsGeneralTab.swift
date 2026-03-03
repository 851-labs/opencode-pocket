#if os(macOS)
  import SwiftUI

  struct MacSettingsGeneralTab: View {
    @Environment(WorkspaceStore.self) private var store

    var body: some View {
      @Bindable var store = store

      Form {
        Section("Feed") {
          FeedToggleRow(
            title: "Show reasoning summaries",
            detail: "Display model reasoning summaries in the timeline",
            isOn: $store.showReasoningSummaries
          )

          FeedToggleRow(
            title: "Expand shell tool parts",
            detail: "Show shell tool parts expanded by default in the timeline",
            isOn: $store.expandShellToolParts
          )

          FeedToggleRow(
            title: "Expand edit tool parts",
            detail: "Show edit, write, and patch tool parts expanded by default in the timeline",
            isOn: $store.expandEditToolParts
          )
        }

        Section("System Notifications") {
          FeedToggleRow(
            title: "Agent",
            detail: "Show system notification when the agent is complete or needs attention",
            isOn: $store.notifyAgentSystemNotifications
          )

          FeedToggleRow(
            title: "Permissions",
            detail: "Show system notification when a permission is required",
            isOn: $store.notifyPermissionSystemNotifications
          )

          FeedToggleRow(
            title: "Errors",
            detail: "Show system notification when an error occurs",
            isOn: $store.notifyErrorSystemNotifications
          )
        }
      }
      .formStyle(.grouped)
    }
  }

  private struct FeedToggleRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
      Toggle(isOn: $isOn) {
        Text(title)
        Text(detail)
      }
    }
  }

  #Preview("General", traits: .macSettings()) {
    MacSettingsGeneralTab()
      .frame(width: 860, height: 560)
  }
#endif
