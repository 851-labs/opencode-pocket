#if os(macOS)
import SwiftUI

struct MacConnectView: View {
  @Bindable var store: ConnectionStore

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 6) {
        Text("OpenCode Pocket")
          .font(.largeTitle.weight(.semibold))

        Text("Connect to your OpenCode server")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Form {
        Section("Server") {
          TextField("Base URL", text: $store.baseURL)
            .accessibilityIdentifier("connect.baseURL")

          TextField("Workspace directory (optional)", text: $store.directory)
            .accessibilityIdentifier("connect.directory")
        }

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

        Button {
          Task {
            await store.connect()
          }
        } label: {
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
    }
    .padding(24)
    .frame(minWidth: 720, minHeight: 520, alignment: .topLeading)
  }
}
#endif
