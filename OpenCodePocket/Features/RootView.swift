import SwiftUI

struct RootView: View {
  @Bindable var store: AppStore

  var body: some View {
#if os(macOS)
    Group {
      if store.isConnected {
        MacWorkspaceView(store: store)
      } else {
        MacConnectView(store: store)
      }
    }
#else
    Group {
      if store.isConnected {
        WorkspaceView(store: store)
      } else {
        ConnectView(store: store)
      }
    }
#endif
  }
}
