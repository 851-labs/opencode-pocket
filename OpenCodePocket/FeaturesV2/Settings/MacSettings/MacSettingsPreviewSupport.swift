#if os(macOS)
  import Foundation
  import SwiftUI

  @MainActor
  struct MacSettingsPreviewGraph {
    let connection: ConnectionStore
    let workspace: WorkspaceStore
  }

  @MainActor
  enum MacSettingsPreviewStore {
    private static let suiteName = "sh.851.opencode-pocket.previews.macsettings"

    static func makeGraph() -> MacSettingsPreviewGraph {
      let defaults = UserDefaults(suiteName: suiteName) ?? .standard
      defaults.removePersistentDomain(forName: suiteName)

      let settingsStore = ConnectionSettingsStore(defaults: defaults)
      settingsStore.saveSettings(makePreviewSettings())
      let graph = StoreGraphFactory.make(
        settingsStore: settingsStore,
        allowsPersistence: false,
        configureWorkspace: { workspace in
          workspace.seedPreviewWorkspace()
        }
      )

      return MacSettingsPreviewGraph(connection: graph.connection, workspace: graph.workspace)
    }

    private static func makePreviewSettings() -> ConnectionSettings {
      ConnectionSettings(
        baseURL: "http://127.0.0.1:4096",
        username: "",
        useBasicAuth: false,
        directory: "/tmp/opencode-pocket-preview",
        selectedAgent: "build",
        selectedProviderID: nil,
        selectedModelID: nil,
        selectedModelVariant: nil,
        hiddenModelKeys: [],
        projects: [],
        selectedProjectID: nil,
        showReasoningSummaries: false,
        expandShellToolParts: true,
        expandEditToolParts: false
      )
    }
  }

  @MainActor
  extension View {
    func withMacSettingsPreviewEnv() -> some View {
      let graph = MacSettingsPreviewStore.makeGraph()
      return withAppDependencyGraph(connection: graph.connection, workspace: graph.workspace)
    }
  }
#endif
