import SwiftUI

@main
struct OpenCodePocketApp: App {
  @State private var store = AppStore()

  var body: some Scene {
    WindowGroup {
      RootView()
        .withAppDependencyGraph(connection: store.connection, workspace: store.workspace)
    }

    #if os(macOS)
      Settings {
        MacSettingsView()
          .withAppDependencyGraph(connection: store.connection, workspace: store.workspace)
      }
    #endif
  }
}
