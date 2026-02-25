#if os(macOS)
  import SwiftUI

  struct MacWorkspaceLoadingView: View {
    var body: some View {
      ContentUnavailableView {
        ProgressView()
      } description: {
        Text("Loading workspace...")
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .accessibilityIdentifier("workspace.bootstrap.loading")
    }
  }

  struct MacWorkspaceBootstrapErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
      VStack(spacing: 12) {
        ContentUnavailableView(
          "Unable to Load Workspace",
          systemImage: "exclamationmark.triangle",
          description: Text(message)
        )

        Button("Retry", action: retry)
          .buttonStyle(.borderedProminent)
          .accessibilityIdentifier("workspace.bootstrap.retry")
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
#endif
