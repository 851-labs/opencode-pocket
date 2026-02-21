#if os(macOS)
import SwiftUI

struct MacConnectView: View {
  @Bindable var store: ConnectionStore

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
      serverSection
      authenticationSection
    }
  }

  @ViewBuilder
  private var serverSection: some View {
    Section("Server") {
      TextField("Base URL", text: $store.baseURL)
        .accessibilityIdentifier("connect.baseURL")

      TextField("Workspace directory (optional)", text: $store.directory)
        .accessibilityIdentifier("connect.directory")
    }
  }

  @ViewBuilder
  private var authenticationSection: some View {
    Section("Authentication") {
      Toggle("Use Basic Auth", isOn: $store.useBasicAuth)
        .accessibilityIdentifier("connect.useBasicAuth")

      if store.useBasicAuth {
        TextField("Username", text: $store.username)
          .accessibilityIdentifier("connect.username")

        SecureField("Password", text: $store.password)
          .accessibilityIdentifier("connect.password")
      }
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
      if store.isConnecting {
        ProgressView()
          .controlSize(.small)
      } else {
        Text("Connect")
      }
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
