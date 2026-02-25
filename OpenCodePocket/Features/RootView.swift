import SwiftUI

struct RootView: View {
  @Environment(ConnectionStore.self) private var connection

  private var shouldShowMacConnectFallback: Bool {
    guard !connection.isConnected, !connection.isConnecting else {
      return false
    }

    guard let error = connection.connectionError else {
      return false
    }

    return !error.isEmpty
  }

  var body: some View {
    #if os(macOS)
      if shouldShowMacConnectFallback {
        MacConnectView()
      } else {
        MacWorkspaceView()
      }
    #else
      Group {
        if connection.isConnected {
          connectedContent
        } else {
          disconnectedContent
        }
      }
    #endif
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
