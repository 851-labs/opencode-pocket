#if os(macOS)
  import SwiftUI

  private enum MacSettingsTab: String, CaseIterable, Identifiable {
    case general
    case models

    var id: Self { self }

    var title: String {
      switch self {
      case .general:
        return "General"
      case .models:
        return "Models"
      }
    }

    var systemImage: String {
      switch self {
      case .general:
        return "gearshape"
      case .models:
        return "cpu"
      }
    }
  }

  struct MacSettingsView: View {
    @State private var selectedTab: MacSettingsTab = .general

    var body: some View {
      TabView(selection: $selectedTab) {
        MacSettingsGeneralTab()
          .tag(MacSettingsTab.general)
          .tabItem {
            Label(MacSettingsTab.general.title, systemImage: MacSettingsTab.general.systemImage)
          }

        MacSettingsModelsTab()
          .tag(MacSettingsTab.models)
          .tabItem {
            Label(MacSettingsTab.models.title, systemImage: MacSettingsTab.models.systemImage)
          }
      }
      .frame(minWidth: 860, minHeight: 560)
    }
  }

  #Preview("Settings") {
    MacSettingsView()
      .environment(MacSettingsPreviewStore.makeStore())
  }
#endif
