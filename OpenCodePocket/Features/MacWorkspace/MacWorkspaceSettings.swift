#if os(macOS)
  import OpenCodeModels
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
    @Bindable var store: WorkspaceStore

    @State private var selectedTab: MacSettingsTab = .general

    var body: some View {
      TabView(selection: $selectedTab) {
        MacSettingsGeneralTab(store: store)
          .tag(MacSettingsTab.general)
          .tabItem {
            Label(MacSettingsTab.general.title, systemImage: MacSettingsTab.general.systemImage)
          }

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

  private struct MacSettingsGeneralTab: View {
    @Bindable var store: WorkspaceStore

    var body: some View {
      Form {
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
      }
      .formStyle(.grouped)
    }
  }

  private struct FeedToggleRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
      LabeledContent {
        Toggle("", isOn: $isOn)
          .labelsHidden()
          .toggleStyle(.switch)
      } label: {
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
          Text(detail)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  private struct MacSettingsModelsTab: View {
    @Bindable var store: WorkspaceStore

    var body: some View {
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
                  VStack(alignment: .leading, spacing: 2) {
                    Text(model.modelName)
                      .lineLimit(1)

                    Text(model.modelID)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                  }
                }
              }
            }
          }
        }
        .formStyle(.grouped)
      }
    }
  }
#endif
