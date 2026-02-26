#if os(macOS)
  import Foundation
  import OpenCodeModels
  import SwiftUI

  enum MacSettingsArchivedPreviewScenario {
    case archivedThreads
    case archivedThreadsError
    case noArchivedThreads
  }

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
  enum MacSettingsArchivedPreviewStore {
    static func makeGraph(for scenario: MacSettingsArchivedPreviewScenario) -> MacSettingsPreviewGraph {
      let graph = MacSettingsPreviewStore.makeGraph()

      switch scenario {
      case .archivedThreads:
        seedArchivedThreads(on: graph.workspace)
      case .archivedThreadsError:
        seedArchivedThreads(on: graph.workspace)
        graph.workspace.connection.connectionError = "This OpenCode server version does not support unarchiving yet. Update the server and try again."
      case .noArchivedThreads:
        break
      }

      return graph
    }

    private static func withArchivedTime(_ session: Session, archivedTime: Double?) -> Session {
      Session(
        id: session.id,
        slug: session.slug,
        projectID: session.projectID,
        directory: session.directory,
        parentID: session.parentID,
        title: session.title,
        version: session.version,
        time: SessionTime(created: session.time.created, updated: session.time.updated, archived: archivedTime),
        summary: session.summary,
        share: session.share,
        revert: session.revert
      )
    }

    private static func seedArchivedThreads(on workspace: WorkspaceStore) {
      let now = Date().timeIntervalSince1970 * 1000
      workspace.sessions = workspace.sessions.enumerated().map { index, session in
        let archivedTime = now - Double((index + 1) * 86_400_000)
        return withArchivedTime(session, archivedTime: archivedTime)
      }
      workspace.selectedSessionID = nil
    }
  }

  @MainActor
  extension View {
    func withMacSettingsPreviewEnv() -> some View {
      let graph = MacSettingsPreviewStore.makeGraph()
      return withAppDependencyGraph(connection: graph.connection, workspace: graph.workspace)
    }

    func withMacSettingsArchivedPreviewEnv(
      _ scenario: MacSettingsArchivedPreviewScenario = .archivedThreads
    ) -> some View {
      let graph = MacSettingsArchivedPreviewStore.makeGraph(for: scenario)
      return withAppDependencyGraph(connection: graph.connection, workspace: graph.workspace)
    }
  }
#endif
