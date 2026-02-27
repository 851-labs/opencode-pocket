#if os(macOS)
  import SwiftUI

  struct MacWorkspaceSidebarToolbar: ToolbarContent {
    let presentProjectPicker: () -> Void

    @ToolbarContentBuilder
    var body: some ToolbarContent {
      ToolbarItem(placement: .automatic) {
        Button(action: presentProjectPicker) {
          Image(systemName: "folder.badge.plus")
        }
        .accessibilityIdentifier("projects.add")
        .help("Add Project")
      }
    }
  }
#endif
