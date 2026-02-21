import Observation

@MainActor
@Observable
final class AppStore {
  let connection: ConnectionStore
  let workspace: WorkspaceStore

  init(settingsStore: ConnectionSettingsStore = ConnectionSettingsStore()) {
    let connection = ConnectionStore(settingsStore: settingsStore)
    let workspace = WorkspaceStore(connection: connection)

    self.connection = connection
    self.workspace = workspace

    connection.workspace = workspace

    if connection.isMockWorkspace {
      workspace.seedMockWorkspace()
    }
  }
}
