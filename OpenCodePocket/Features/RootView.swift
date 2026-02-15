import SwiftUI

struct RootView: View {
    @Bindable var store: AppStore

    var body: some View {
        Group {
            if store.isConnected {
                WorkspaceView(store: store)
            } else {
                ConnectView(store: store)
            }
        }
    }
}
