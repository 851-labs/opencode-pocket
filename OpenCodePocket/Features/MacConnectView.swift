#if os(macOS)
  import SwiftUI

  struct MacConnectView: View {
    @Environment(ConnectionStore.self) private var store

    var body: some View {
      VStack(alignment: .leading, spacing: 20) {
        header
        formContent
        footer
      }
      .padding(24)
      .frame(minWidth: 720, minHeight: 520, alignment: .topLeading)
    }

    private var header: some View {
      VStack(alignment: .leading, spacing: 6) {
        Text("OpenCode Pocket")
          .font(.largeTitle.weight(.semibold))

        Text("Connect to your OpenCode server")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }

    private var formContent: some View {
      Form {
        ConnectionServerSection(applyInputTraits: false)
        ConnectionAuthenticationSection(applyInputTraits: false)
      }
    }

    private var footer: some View {
      HStack(spacing: 12) {
        Text("Server state: \(store.eventConnectionState)")
          .font(.footnote)
          .foregroundStyle(.secondary)

        if let error = store.connectionError {
          Text(error)
            .font(.footnote)
            .foregroundStyle(.red)
            .lineLimit(2)
            .accessibilityIdentifier("connect.error")
        }

        Spacer()

        connectButton
      }
    }

    private var connectButton: some View {
      Button(action: connect) {
        ConnectionPrimaryButtonLabel(isConnecting: store.isConnecting, inlineProgressAndText: false)
      }
      .keyboardShortcut(.defaultAction)
      .disabled(store.isConnecting)
      .accessibilityIdentifier("connect.button")
    }

    private func connect() {
      Task {
        await store.connect()
      }
    }
  }
#endif
