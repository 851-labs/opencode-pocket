import SwiftUI

struct ConnectView: View {
  @Environment(ConnectionStore.self) private var store

  var body: some View {
    NavigationStack {
      formContent
    }
  }

  private var formContent: some View {
    Form {
      ConnectionServerSection(applyInputTraits: true)
      ConnectionAuthenticationSection(applyInputTraits: true)
      actionsSection
    }
    .navigationTitle("OpenCode Pocket")
    .safeAreaInset(edge: .bottom) {
      statusFooter
    }
  }

  @ViewBuilder
  private var actionsSection: some View {
    Section {
      connectButton

      if let error = store.connectionError {
        Text(error)
          .font(.footnote)
          .foregroundStyle(.red)
          .accessibilityIdentifier("connect.error")
      }
    }
  }

  private var connectButton: some View {
    Button(action: connect) {
      ConnectionPrimaryButtonLabel(isConnecting: store.isConnecting, inlineProgressAndText: true)
    }
    .disabled(store.isConnecting)
    .accessibilityIdentifier("connect.button")
  }

  private var statusFooter: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("Remote-first iOS client for OpenCode")
        .font(.footnote)
        .foregroundStyle(.secondary)
      Text("Server state: \(store.eventConnectionState)")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(.thinMaterial)
  }

  private func connect() {
    Task {
      await store.connect()
    }
  }
}
