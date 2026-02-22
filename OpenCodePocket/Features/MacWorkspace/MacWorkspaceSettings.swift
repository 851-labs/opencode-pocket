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
    NavigationSplitView {
      List(MacSettingsTab.allCases, selection: $selectedTab) { tab in
        Label(tab.title, systemImage: tab.systemImage)
          .tag(tab)
      }
      .navigationTitle("Settings")
      .navigationSplitViewColumnWidth(min: 180, ideal: 220)
    } detail: {
      switch selectedTab {
      case .models:
        MacSettingsModelsTab(store: store)
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

  @State private var query = ""

  private var filteredGroups: [ModelProviderGroup] {
    let search = query.trimmedForInput.lowercased()
    guard !search.isEmpty else {
      return store.modelSettingsProviderGroups
    }

    return store.modelSettingsProviderGroups.compactMap { group in
      let providerMatch = group.providerName.lowercased().contains(search)
      let matches = group.models.filter { model in
        providerMatch
          || model.modelName.lowercased().contains(search)
          || model.modelID.lowercased().contains(search)
      }

      guard !matches.isEmpty else {
        return nil
      }

      return ModelProviderGroup(
        providerID: group.providerID,
        providerName: group.providerName,
        models: matches
      )
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Models")
        .font(.title2.weight(.semibold))

      if filteredGroups.isEmpty {
        ContentUnavailableView(
          "No Models Found",
          systemImage: "magnifyingglass",
          description: Text("Try a different search term.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(filteredGroups) { group in
              VStack(alignment: .leading, spacing: 8) {
                Text(group.providerName)
                  .font(.headline)

                VStack(spacing: 0) {
                  ForEach(group.models) { model in
                    HStack(spacing: 12) {
                      VStack(alignment: .leading, spacing: 2) {
                        Text(model.modelName)
                          .font(.body)
                          .lineLimit(1)

                        Text(model.modelID)
                          .font(.caption)
                          .foregroundStyle(.secondary)
                          .lineLimit(1)
                      }

                      Spacer(minLength: 0)

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
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    if model.id != group.models.last?.id {
                      Divider()
                    }
                  }
                }
                .background(
                  RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.1))
                )
              }
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .searchable(text: $query, prompt: "Search models")
  }
}
#endif
