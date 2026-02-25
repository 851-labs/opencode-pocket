import Foundation
import Observation

#if os(macOS)
  import AppKit
#endif

@MainActor
final class AppStore {
  let connection: ConnectionStore
  let workspace: WorkspaceStore

  #if os(macOS)
    private var terminationObserver: NSObjectProtocol?
  #endif

  init(settingsStore: ConnectionSettingsStore = ConnectionSettingsStore()) {
    let connection = ConnectionStore(settingsStore: settingsStore)
    let workspace = WorkspaceStore(connection: connection)

    self.connection = connection
    self.workspace = workspace

    connection.workspace = workspace

    if connection.isMockWorkspace {
      workspace.seedMockWorkspace()
    }

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

      if !connection.isMockWorkspace {
        Task { [weak connection] in
          await connection?.connect()
        }
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
