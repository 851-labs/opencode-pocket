#if os(macOS)
  import Foundation
  import OpenCodeModels
  import SwiftUI

  enum MacSettingsPreviewScenario {
    case seeded
    case archived
    case archivedEmpty
    case archivedError
  }

  @MainActor
  private struct MacSettingsPreviewGraph {
    let connection: ConnectionStore
    let workspace: WorkspaceStore
  }

  @MainActor
  private enum MacSettingsPreviewStore {
    private static let suiteName = "sh.851.opencode-pocket.previews.macsettings"

    static func makeGraph(for scenario: MacSettingsPreviewScenario = .seeded) -> MacSettingsPreviewGraph {
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
          workspace.seedPreviewWorkspace()

          switch scenario {
          case .seeded:
            break
          case .archived:
            seedArchivedThreads(on: workspace)
          case .archivedEmpty:
            break
          case .archivedError:
            seedArchivedThreads(on: workspace)
            workspace.workspaceError = "This OpenCode server version does not support unarchiving yet. Update the server and try again."
          }
        }
      )

      return MacSettingsPreviewGraph(connection: graph.connection, workspace: graph.workspace)
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
        time: SessionTimestamps(created: session.time.created, updated: session.time.updated, archived: archivedTime),
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
  private struct MacSettingsPreviewModifier: PreviewModifier {
    let scenario: MacSettingsPreviewScenario

    func body(content: Content, context: Void) -> some View {
      let graph = MacSettingsPreviewStore.makeGraph(for: scenario)

      return content
        .environment(graph.connection)
        .environment(graph.workspace)
    }
  }

  @MainActor
  extension PreviewTrait where T == Preview.ViewTraits {
    static var macSettings: Self {
      .macSettings(.seeded)
    }

    static func macSettings(_ scenario: MacSettingsPreviewScenario = .seeded) -> Self {
      .modifier(MacSettingsPreviewModifier(scenario: scenario))
    }
  }
#endif
