import SwiftUI

struct ConnectionServerSection: View {
  @Bindable var store: ConnectionStore
  let applyInputTraits: Bool

  var body: some View {
    Section("Server") {
      baseURLField
      directoryField
    }
  }

  @ViewBuilder
  private var baseURLField: some View {
    #if os(iOS)
      if applyInputTraits {
        TextField("Base URL", text: $store.baseURL)
          .keyboardType(.URL)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
          .accessibilityIdentifier("connect.baseURL")
      } else {
        TextField("Base URL", text: $store.baseURL)
          .accessibilityIdentifier("connect.baseURL")
      }
    #else
      TextField("Base URL", text: $store.baseURL)
        .accessibilityIdentifier("connect.baseURL")
    #endif
  }

  @ViewBuilder
  private var directoryField: some View {
    #if os(iOS)
      if applyInputTraits {
        TextField("Workspace directory (optional)", text: $store.directory)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
          .accessibilityIdentifier("connect.directory")
      } else {
        TextField("Workspace directory (optional)", text: $store.directory)
          .accessibilityIdentifier("connect.directory")
      }
    #else
      TextField("Workspace directory (optional)", text: $store.directory)
        .accessibilityIdentifier("connect.directory")
    #endif
  }
}

struct ConnectionAuthenticationSection: View {
  @Bindable var store: ConnectionStore
  let applyInputTraits: Bool

  var body: some View {
    Section("Authentication") {
      Toggle("Use Basic Auth", isOn: $store.useBasicAuth)
        .accessibilityIdentifier("connect.useBasicAuth")

      if store.useBasicAuth {
        usernameField

        SecureField("Password", text: $store.password)
          .accessibilityIdentifier("connect.password")
      }
    }
  }

  @ViewBuilder
  private var usernameField: some View {
    #if os(iOS)
      if applyInputTraits {
        TextField("Username", text: $store.username)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
          .accessibilityIdentifier("connect.username")
      } else {
        TextField("Username", text: $store.username)
          .accessibilityIdentifier("connect.username")
      }
    #else
      TextField("Username", text: $store.username)
        .accessibilityIdentifier("connect.username")
    #endif
  }
}

struct ConnectionPrimaryButtonLabel: View {
  let isConnecting: Bool
  let inlineProgressAndText: Bool

  var body: some View {
    Group {
      if inlineProgressAndText {
        HStack {
          if isConnecting {
            ProgressView()
              .controlSize(.small)
          }
          Text(isConnecting ? "Connecting..." : "Connect")
        }
      } else if isConnecting {
        ProgressView()
          .controlSize(.small)
      } else {
        Text("Connect")
      }
    }
  }
}
