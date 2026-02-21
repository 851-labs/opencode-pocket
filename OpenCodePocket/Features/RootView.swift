import SwiftUI

struct RootView: View {
  @Bindable var store: AppStore

  var body: some View {
#if os(macOS)
    Group {
      if store.connection.isConnected {
        MacWorkspaceView(store: store.workspace)
      } else {
        MacConnectView(store: store.connection)
      }
    }
#else
    Group {
      if store.connection.isConnected {
        WorkspaceView(store: store.workspace)
      } else {
        ConnectView(store: store.connection)
      }
    }
#endif
  }
}
