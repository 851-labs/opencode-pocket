import SwiftUI

struct RootView: View {
  @Bindable var connection: ConnectionStore
  @Bindable var workspace: WorkspaceStore

  var body: some View {
    Group {
      if connection.isConnected {
        connectedContent
      } else {
        disconnectedContent
      }
    }
  }

  @ViewBuilder
  private var connectedContent: some View {
#if os(macOS)
    MacWorkspaceView(store: workspace)
#else
    WorkspaceView(store: workspace)
#endif
  }

  @ViewBuilder
  private var disconnectedContent: some View {
#if os(macOS)
    MacConnectView(store: connection)
#else
    ConnectView(store: connection)
#endif
  }
}
