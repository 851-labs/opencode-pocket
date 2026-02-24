#if os(macOS)
  import OpenCodeModels
  import SwiftUI

  private enum MacSettingsTab: String, CaseIterable, Identifiable {
    case models

    var id: Self { self }

    var title: String {
      switch self {
      case .models:
        return "Models"
      }
    }

    var systemImage: String {
      switch self {
      case .models:
        return "cpu"
      }
    }
  }

  struct MacSettingsView: View {
    @Bindable var store: WorkspaceStore

    @State private var selectedTab: MacSettingsTab = .models

    var body: some View {
      TabView(selection: $selectedTab) {
        MacSettingsModelsTab(store: store)
          .tag(MacSettingsTab.models)
          .tabItem {
            Label(MacSettingsTab.models.title, systemImage: MacSettingsTab.models.systemImage)
          }
      }
      .task {
        await store.refreshAgentAndModelOptions()
      }
      .frame(minWidth: 860, minHeight: 560)
    }
  }

  private struct MacSettingsModelsTab: View {
    @Bindable var store: WorkspaceStore

    var body: some View {
      VStack {
        if store.modelSettingsProviderGroups.isEmpty {
          ContentUnavailableView(
            "No Models Found",
            systemImage: "magnifyingglass",
            description: Text("Model list is currently unavailable.")
          )
        } else {
          Form {
            ForEach(store.modelSettingsProviderGroups) { group in
              Section(group.providerName) {
                ForEach(group.models) { model in
                  LabeledContent {
                    Toggle(
                      "",
                      isOn: Binding(
                        get: { store.isModelVisible(model) },
                        set: { visible in
                          store.setModelVisibility(model, isVisible: visible)
                        }
                      )
                    )
                    .labelsHidden()
                    .toggleStyle(.switch)
                  } label: {
                    Text(model.modelName)
                      .lineLimit(1)

                    //                  Text(model.modelID)
                    //                    .lineLimit(1)
                  }
                }
              }
            }
          }
          .formStyle(.grouped)
        }
      }
    }
  }
#endif
