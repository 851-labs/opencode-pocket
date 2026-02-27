import Foundation
import Observation

#if os(macOS)
  import AppKit
#endif

@MainActor
struct StoreGraph {
  let connection: ConnectionStore
  let workspace: WorkspaceStore
}

@MainActor
enum StoreGraphFactory {
  static func make(
    settingsStore: ConnectionSettingsStore = ConnectionSettingsStore(),
    workspaceSettingsStore: WorkspaceSettingsStore = WorkspaceSettingsStore(),
    allowsPersistence: Bool = true,
    configureWorkspace: ((WorkspaceStore) -> Void)? = nil
  ) -> StoreGraph {
    let connection = ConnectionStore(settingsStore: settingsStore)
    let workspace = WorkspaceStore(
      connection: connection,
      settingsStore: workspaceSettingsStore,
      allowsPersistence: allowsPersistence
    )
    connection.workspace = workspace
    configureWorkspace?(workspace)
    return StoreGraph(connection: connection, workspace: workspace)
  }
}

@MainActor
final class AppStore {
  let connection: ConnectionStore
  let workspace: WorkspaceStore

  #if os(macOS)
    private var terminationObserver: NSObjectProtocol?
  #endif

  init(settingsStore: ConnectionSettingsStore = ConnectionSettingsStore()) {
    let graph = StoreGraphFactory.make(settingsStore: settingsStore)
    let connection = graph.connection
    let workspace = graph.workspace

    self.connection = connection
    self.workspace = workspace

    #if os(macOS)
      terminationObserver = NotificationCenter.default.addObserver(
        forName: NSApplication.willTerminateNotification,
        object: nil,
        queue: nil
      ) { [weak connection] _ in
        Task { @MainActor [weak connection] in
          connection?.stopManagedLocalServerForTermination()
        }
      }

      Task { [weak connection] in
        await connection?.connect()
      }
    #endif
  }

  deinit {
    #if os(macOS)
      if let terminationObserver {
        NotificationCenter.default.removeObserver(terminationObserver)
      }
    #endif
  }
}
