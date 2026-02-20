import SwiftUI

struct ConnectView: View {
  @Bindable var store: AppStore

  var body: some View {
    NavigationStack {
      Form {
        Section("Server") {
          TextField("Base URL", text: $store.baseURL)
            .keyboardType(.URL)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .accessibilityIdentifier("connect.baseURL")

          TextField("Workspace directory (optional)", text: $store.directory)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .accessibilityIdentifier("connect.directory")
        }

        Section("Authentication") {
          Toggle("Use Basic Auth", isOn: $store.useBasicAuth)
            .accessibilityIdentifier("connect.useBasicAuth")

          if store.useBasicAuth {
            TextField("Username", text: $store.username)
              .autocorrectionDisabled()
              .textInputAutocapitalization(.never)
              .accessibilityIdentifier("connect.username")

            SecureField("Password", text: $store.password)
              .accessibilityIdentifier("connect.password")
          }
        }

        Section {
          Button {
            Task {
              await store.connect()
            }
          } label: {
            HStack {
              if store.isConnecting {
                ProgressView()
                  .controlSize(.small)
              }
              Text(store.isConnecting ? "Connecting..." : "Connect")
            }
          }
          .disabled(store.isConnecting)
          .accessibilityIdentifier("connect.button")

          if let error = store.connectionError {
            Text(error)
              .font(.footnote)
              .foregroundStyle(.red)
              .accessibilityIdentifier("connect.error")
          }
        }
      }
      .navigationTitle("OpenCode Pocket")
      .safeAreaInset(edge: .bottom) {
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
    }
  }
}
