import SwiftUI

struct RootView: View {
  @Environment(ConnectionStore.self) private var connection
  @Environment(WorkspaceStore.self) private var workspace

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
      MacWorkspaceView()
    #else
      WorkspaceView()
    #endif
  }

  @ViewBuilder
  private var disconnectedContent: some View {
    #if os(macOS)
      MacConnectView()
    #else
      ConnectView()
    #endif
  }
}
