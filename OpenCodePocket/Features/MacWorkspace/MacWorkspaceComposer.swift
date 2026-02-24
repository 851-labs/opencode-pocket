#if os(macOS)
  import SwiftUI

  struct MacComposerView: View {
    @Bindable var store: WorkspaceStore
    let sessionID: String

    var body: some View {
      VStack(spacing: 10) {
        if let permission = store.currentPermissionRequest(for: sessionID) {
          MacPermissionPromptCard(store: store, sessionID: sessionID, request: permission)
        }

        if let question = store.currentQuestionRequest(for: sessionID) {
          MacQuestionPromptCard(store: store, sessionID: sessionID, request: question)
        }

        let todos = store.todosBySession[sessionID] ?? []
        if !todos.isEmpty {
          MacTodoDockCard(todos: todos)
        }

        let composerBlocked = store.isComposerBlocked(for: sessionID)
        let isRunning = store.isSessionRunning(sessionID)

        TextField("Message", text: $store.draftMessage, axis: .vertical)
          .lineLimit(1 ... 8)
          .disabled(composerBlocked)

        if composerBlocked {
          Text("Respond to the active prompt before sending another message.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        HStack(spacing: 10) {
          agentMenu

          modelMenu

          effortMenu

          Spacer()

          Text(store.statusLabel(for: sessionID))
            .font(.caption)
            .foregroundStyle(.secondary)

          Button(store.isSessionRunning(sessionID) ? "Abort" : "Send") {
            Task {
              if store.isSessionRunning(sessionID) {
                await store.abort(sessionID: sessionID)
              } else {
                await store.sendDraftMessage(in: sessionID)
              }
            }
          }
          .buttonStyle(.borderedProminent)
          .disabled(!isRunning && (composerBlocked || store.draftMessage.trimmedForInput.isEmpty))
          .keyboardShortcut(.defaultAction)
        }
      }
    }

    private var agentMenu: some View {
      Menu {
        if store.availableAgents.isEmpty {
          Button("No agents available") {}
            .disabled(true)
        } else {
          ForEach(store.availableAgents) { agent in
            Button {
              store.selectAgent(named: agent.name)
            } label: {
              if store.selectedAgentName == agent.name {
                Label(agent.name.capitalized, systemImage: "checkmark")
              } else {
                Text(agent.name.capitalized)
              }
            }
          }
        }
      } label: {
        Label(store.selectedAgentName.capitalized, systemImage: "wand.and.stars")
          .lineLimit(1)
      }
    }

    private var modelMenu: some View {
      Menu {
        if store.modelProviderGroups.isEmpty {
          Button("No models available") {}
            .disabled(true)
        } else {
          ForEach(store.modelProviderGroups) { provider in
            Menu(provider.providerName) {
              ForEach(provider.models) { model in
                Button {
                  store.selectModel(model)
                } label: {
                  if store.selectedModel?.providerID == model.providerID && store.selectedModel?.modelID == model.modelID {
                    Label(model.modelName, systemImage: "checkmark")
                  } else {
                    Text(model.modelName)
                  }
                }
              }
            }
          }
        }
      } label: {
        Label(store.selectedModelDisplayName, systemImage: "cpu")
          .lineLimit(1)
      }
    }

    private var effortMenu: some View {
      Menu {
        Button {
          store.selectModelVariant(nil)
        } label: {
          if store.selectedModelVariant == nil {
            Label("Default", systemImage: "checkmark")
          } else {
            Text("Default")
          }
        }

        ForEach(store.selectedModelVariants, id: \.self) { variant in
          Button {
            store.selectModelVariant(variant)
          } label: {
            if store.selectedModelVariant == variant {
              Label(variant.capitalized, systemImage: "checkmark")
            } else {
              Text(variant.capitalized)
            }
          }
        }
      } label: {
        Text(store.selectedModelVariantDisplayName)
          .lineLimit(1)
      }
    }
  }
#endif
