import SwiftUI

struct RootView: View {
  @Bindable var connection: ConnectionStore
  @Bindable var workspace: WorkspaceStore

  var body: some View {
#if os(macOS)
    Group {
      if connection.isConnected {
        MacWorkspaceView(store: workspace)
      } else {
        MacConnectView(store: connection)
      }
    }
#else
    Group {
      if connection.isConnected {
        WorkspaceView(store: workspace)
      } else {
        ConnectView(store: connection)
      }
    }
#endif
  }
}
