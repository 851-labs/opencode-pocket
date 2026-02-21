import SwiftUI

@main
struct OpenCodePocketApp: App {
  @State private var store = AppStore()

  var body: some Scene {
    WindowGroup {
      RootView(connection: store.connection, workspace: store.workspace)
    }

#if os(macOS)
    Settings {
      MacSettingsView(store: store.workspace)
    }
#endif
  }
}
