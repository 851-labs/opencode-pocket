#if os(macOS)
  import AppKit
  import SwiftUI

  struct MacSettingsGeneralTab: View {
    @Environment(WorkspaceStore.self) private var store

    var body: some View {
      @Bindable var store = store

      Form {
        Section {
          DefaultOpenDestinationRow(destination: $store.defaultOpenDestination)
        }

        Section("Feed") {
          FeedToggleRow(
            title: "Show reasoning summaries",
            detail: "Display model reasoning summaries in the timeline",
            isOn: $store.showReasoningSummaries
          )

          FeedToggleRow(
            title: "Expand shell tool parts",
            detail: "Show shell tool parts expanded by default in the timeline",
            isOn: $store.expandShellToolParts
          )

          FeedToggleRow(
            title: "Expand edit tool parts",
            detail: "Show edit, write, and patch tool parts expanded by default in the timeline",
            isOn: $store.expandEditToolParts
          )
        }

        Section("System Notifications") {
          FeedToggleRow(
            title: "Agent",
            detail: "Show system notification when the agent is complete or needs attention",
            isOn: $store.notifyAgentSystemNotifications
          )

          FeedToggleRow(
            title: "Permissions",
            detail: "Show system notification when a permission is required",
            isOn: $store.notifyPermissionSystemNotifications
          )

          FeedToggleRow(
            title: "Errors",
            detail: "Show system notification when an error occurs",
            isOn: $store.notifyErrorSystemNotifications
          )
        }
      }
      .formStyle(.grouped)
    }
  }

  private struct DefaultOpenDestinationRow: View {
    @Binding var destination: DefaultOpenDestination

    private var orderedDestinations: [DefaultOpenDestination] {
      DefaultOpenDestination.allCases.sorted {
        $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
      }
    }

    var body: some View {
      LabeledContent {
        Picker("Default open destination", selection: $destination) {
          ForEach(orderedDestinations) { destination in
            DefaultOpenDestinationOptionLabel(destination: destination)
              .tag(destination)
          }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .accessibilityIdentifier("settings.general.defaultOpenDestination")
      } label: {
        Text("Default open destination")
        Text("Where files and folders open by default")
      }
    }
  }

  private struct DefaultOpenDestinationOptionLabel: View {
    let destination: DefaultOpenDestination

    var body: some View {
      Label {
        Text(destination.displayName)
      } icon: {
        if let icon = destination.macAppIcon {
          Image(nsImage: icon)
            .resizable()
            .frame(width: 12, height: 12)
        } else {
          Image(systemName: destination.systemImage)
        }
      }
    }
  }

  private extension DefaultOpenDestination {
    var macAppIcon: NSImage? {
      let workspace = NSWorkspace.shared

      for bundleIdentifier in macBundleIdentifiers {
        if let url = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) {
          return workspace.icon(forFile: url.path)
        }
      }

      for appName in macAppNames {
        for searchDirectory in appSearchDirectories {
          let path = URL(fileURLWithPath: searchDirectory)
            .appendingPathComponent("\(appName).app")
            .path
          if FileManager.default.fileExists(atPath: path) {
            return workspace.icon(forFile: path)
          }
        }
      }

      return nil
    }

    var appSearchDirectories: [String] {
      [
        "/Applications",
        "/System/Applications",
        NSHomeDirectory() + "/Applications",
      ]
    }

    var macBundleIdentifiers: [String] {
      switch self {
      case .vscode:
        return ["com.microsoft.VSCode", "com.microsoft.VSCodeInsiders"]
      case .cursor:
        return ["com.todesktop.230313mzl4w4u92"]
      case .finder:
        return ["com.apple.finder"]
      case .terminal:
        return ["com.apple.Terminal"]
      case .ghostty:
        return ["com.mitchellh.ghostty"]
      case .xcode:
        return ["com.apple.dt.Xcode"]
      case .androidStudio:
        return ["com.google.android.studio", "com.google.android.studio-EAP"]
      case .zed:
        return ["dev.zed.Zed"]
      }
    }

    var macAppNames: [String] {
      switch self {
      case .vscode:
        return ["Visual Studio Code", "Code"]
      case .cursor:
        return ["Cursor"]
      case .finder:
        return ["Finder"]
      case .terminal:
        return ["Terminal"]
      case .ghostty:
        return ["Ghostty"]
      case .xcode:
        return ["Xcode"]
      case .androidStudio:
        return ["Android Studio"]
      case .zed:
        return ["Zed"]
      }
    }
  }

  private struct FeedToggleRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
      Toggle(isOn: $isOn) {
        Text(title)
        Text(detail)
      }
    }
  }

  #Preview("General", traits: .macSettings()) {
    MacSettingsGeneralTab()
      .frame(width: 860, height: 560)
  }
#endif
