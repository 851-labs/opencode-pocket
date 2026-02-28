#if os(macOS)
  import SwiftUI

  struct MacSettingsModelsTab: View {
    @Environment(WorkspaceStore.self) private var store

    var body: some View {
      @Bindable var store = store

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
                  Toggle(isOn: Binding(
                    get: { store.isModelVisible(model) },
                    set: { visible in
                      store.setModelVisibility(model, isVisible: visible)
                    }
                  )) {
                    Text(model.modelName)
                    Text(model.modelID)
                  }
                }
              }
            }
          }
          .formStyle(.grouped)
        }
      }
      .task {
        await store.refreshAgentAndModelOptions()
      }
    }
  }

  #Preview("Models") {
    MacSettingsModelsTab()
      .withMacSettingsPreviewEnv()
      .frame(width: 860, height: 560)
  }
#endif
