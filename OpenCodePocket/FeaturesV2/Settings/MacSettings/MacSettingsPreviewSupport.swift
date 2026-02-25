#if os(macOS)
  import Foundation

  @MainActor
  enum MacSettingsPreviewStore {
    static func makeStore() -> WorkspaceStore {
      let suiteName = "sh.851.opencode-pocket.previews.macsettings"
      let defaults = UserDefaults(suiteName: suiteName) ?? .standard
      defaults.removePersistentDomain(forName: suiteName)

      let settingsStore = ConnectionSettingsStore(defaults: defaults)
      let connection = ConnectionStore(settingsStore: settingsStore)
      let store = WorkspaceStore(connection: connection)
      connection.workspace = store
      store.seedMockWorkspace()
      return store
    }
  }
#endif
