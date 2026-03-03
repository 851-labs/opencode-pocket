#if os(macOS)
  import Foundation
  import SwiftUI

  enum MacWorkspacePreviewScenario {
    case seeded
    case pinned
    case emptyProjects
  }

  @MainActor
  private struct MacWorkspacePreviewGraph {
    let connection: ConnectionStore
    let workspace: WorkspaceStore
  }

  @MainActor
  private enum MacWorkspacePreviewStore {
    private static let suiteName = "sh.851.opencode-pocket.previews.macworkspace"

    static func makeGraph(for scenario: MacWorkspacePreviewScenario = .seeded) -> MacWorkspacePreviewGraph {
      let defaults = UserDefaults(suiteName: suiteName) ?? .standard
      defaults.removePersistentDomain(forName: suiteName)

      let settingsStore = ConnectionSettingsStore(defaults: defaults)
      let workspaceSettingsStore = WorkspaceSettingsStore(defaults: defaults)
      settingsStore.saveSettings(makePreviewSettings())
      let graph = StoreGraphFactory.make(
        settingsStore: settingsStore,
        workspaceSettingsStore: workspaceSettingsStore,
        allowsPersistence: false,
        configureWorkspace: { workspace in
          switch scenario {
          case .seeded:
            workspace.seedPreviewWorkspace()
          case .pinned:
            workspace.seedPreviewWorkspace()
            if let firstSessionID = workspace.sessions.first?.id {
              workspace.pinnedSessionIDs.insert(firstSessionID)
            }
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
        directory: "/tmp/opencode-pocket-preview"
      )
    }
  }

  @MainActor
  private struct MacWorkspacePreviewModifier: PreviewModifier {
    let scenario: MacWorkspacePreviewScenario

    func body(content: Content, context: Void) -> some View {
      let graph = MacWorkspacePreviewStore.makeGraph(for: scenario)
      return content
        .environment(graph.connection)
        .environment(graph.workspace)
    }
  }

  @MainActor
  extension PreviewTrait where T == Preview.ViewTraits {
    static var macWorkspace: Self {
      .macWorkspace(.seeded)
    }

    static func macWorkspace(_ scenario: MacWorkspacePreviewScenario = .seeded) -> Self {
      .modifier(MacWorkspacePreviewModifier(scenario: scenario))
    }
  }
#endif
