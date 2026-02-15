import SwiftUI

struct RootView: View {
    @Bindable var store: AppStore

    var body: some View {
        Group {
            if store.isConnected {
                NavigationSplitView {
                    SessionsView(store: store)
                } detail: {
                    if let selectedSessionID = store.selectedSessionID {
                        ChatView(store: store, sessionID: selectedSessionID)
                    } else {
                        ContentUnavailableView(
                            "No Session Selected",
                            systemImage: "bubble.left.and.bubble.right",
                            description: Text("Create or pick a session from the sidebar.")
                        )
                    }
                }
            } else {
                ConnectView(store: store)
            }
        }
    }
}
