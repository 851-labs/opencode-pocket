#if os(macOS)
  import SwiftUI

  struct MacSettingsGeneralTab: View {
    @Bindable var store: WorkspaceStore

    var body: some View {
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

  #Preview("General") {
    MacSettingsGeneralTab(store: MacSettingsPreviewStore.makeStore())
      .frame(width: 860, height: 560)
  }
#endif
