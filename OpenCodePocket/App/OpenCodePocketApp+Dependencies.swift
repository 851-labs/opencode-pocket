import SwiftUI

extension View {
  func withAppDependencyGraph(connection: ConnectionStore, workspace: WorkspaceStore) -> some View {
    environment(connection)
      .environment(workspace)
  }
}
