import SwiftUI

@main
struct OpenCodePocketApp: App {
  @State private var store = AppStore()

  var body: some Scene {
    #if os(macOS)
      WindowGroup {
        RootView()
          .withAppDependencyGraph(connection: store.connection, workspace: store.workspace)
      }
      .commands {
        SidebarCommands()
      }

      Settings {
        MacSettingsView()
          .withAppDependencyGraph(connection: store.connection, workspace: store.workspace)
      }
    #else
      WindowGroup {
        RootView()
          .withAppDependencyGraph(connection: store.connection, workspace: store.workspace)
      }
    #endif
  }
}
