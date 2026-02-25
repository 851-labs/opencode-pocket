import SwiftUI

struct ConnectionServerSection: View {
  @Environment(ConnectionStore.self) private var store
  let applyInputTraits: Bool

  private var baseURLBinding: Binding<String> {
    Binding(
      get: { store.baseURL },
      set: { store.baseURL = $0 }
    )
  }

  private var directoryBinding: Binding<String> {
    Binding(
      get: { store.directory },
      set: { store.directory = $0 }
    )
  }

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
        TextField("Base URL", text: baseURLBinding)
          .keyboardType(.URL)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
          .accessibilityIdentifier("connect.baseURL")
      } else {
        TextField("Base URL", text: baseURLBinding)
          .accessibilityIdentifier("connect.baseURL")
      }
    #else
      TextField("Base URL", text: baseURLBinding)
        .accessibilityIdentifier("connect.baseURL")
    #endif
  }

  @ViewBuilder
  private var directoryField: some View {
    #if os(iOS)
      if applyInputTraits {
        TextField("Workspace directory (optional)", text: directoryBinding)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
          .accessibilityIdentifier("connect.directory")
      } else {
        TextField("Workspace directory (optional)", text: directoryBinding)
          .accessibilityIdentifier("connect.directory")
      }
    #else
      TextField("Workspace directory (optional)", text: directoryBinding)
        .accessibilityIdentifier("connect.directory")
    #endif
  }
}

struct ConnectionAuthenticationSection: View {
  @Environment(ConnectionStore.self) private var store
  let applyInputTraits: Bool

  private var useBasicAuthBinding: Binding<Bool> {
    Binding(
      get: { store.useBasicAuth },
      set: { store.useBasicAuth = $0 }
    )
  }

  private var usernameBinding: Binding<String> {
    Binding(
      get: { store.username },
      set: { store.username = $0 }
    )
  }

  private var passwordBinding: Binding<String> {
    Binding(
      get: { store.password },
      set: { store.password = $0 }
    )
  }

  var body: some View {
    Section("Authentication") {
      Toggle("Use Basic Auth", isOn: useBasicAuthBinding)
        .accessibilityIdentifier("connect.useBasicAuth")

      if store.useBasicAuth {
        usernameField

        SecureField("Password", text: passwordBinding)
          .accessibilityIdentifier("connect.password")
      }
    }
  }

  @ViewBuilder
  private var usernameField: some View {
    #if os(iOS)
      if applyInputTraits {
        TextField("Username", text: usernameBinding)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
          .accessibilityIdentifier("connect.username")
      } else {
        TextField("Username", text: usernameBinding)
          .accessibilityIdentifier("connect.username")
      }
    #else
      TextField("Username", text: usernameBinding)
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
