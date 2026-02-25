#if os(macOS)
  import Foundation
  import SwiftUI

  enum MacWorkspacePreviewScenario {
    case seededWorkspace
    case emptyProjects
  }

  @MainActor
  struct MacWorkspacePreviewGraph {
    let connection: ConnectionStore
    let workspace: WorkspaceStore
  }

  @MainActor
  enum MacWorkspacePreviewStore {
    private static let suiteName = "sh.851.opencode-pocket.previews.macworkspace"

    static func makeGraph(for scenario: MacWorkspacePreviewScenario = .seededWorkspace) -> MacWorkspacePreviewGraph {
      let defaults = UserDefaults(suiteName: suiteName) ?? .standard
      defaults.removePersistentDomain(forName: suiteName)

      let settingsStore = ConnectionSettingsStore(defaults: defaults)
      settingsStore.saveSettings(makePreviewSettings())
      let graph = StoreGraphFactory.make(
        settingsStore: settingsStore,
        allowsPersistence: false,
        configureWorkspace: { workspace in
          switch scenario {
          case .seededWorkspace:
            workspace.seedPreviewWorkspace()
          case .emptyProjects:
            workspace.projects = []
            workspace.selectedProjectID = nil
            workspace.selectedSessionID = nil
            workspace.sessions = []
            workspace.messagesBySession = [:]
            workspace.diffsBySession = [:]
            workspace.permissionsBySession = [:]
            workspace.questionsBySession = [:]
            workspace.todosBySession = [:]
          }
        }
      )

      return MacWorkspacePreviewGraph(connection: graph.connection, workspace: graph.workspace)
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
    func withMacWorkspacePreviewEnv(_ scenario: MacWorkspacePreviewScenario = .seededWorkspace) -> some View {
      let graph = MacWorkspacePreviewStore.makeGraph(for: scenario)
      return withAppDependencyGraph(connection: graph.connection, workspace: graph.workspace)
    }
  }
#endif
