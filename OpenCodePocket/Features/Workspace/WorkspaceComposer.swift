import SwiftUI

#if os(iOS)

struct WorkspaceComposer: View {
  @Bindable var store: WorkspaceStore
  let sessionID: String

  var body: some View {
    GlassEffectContainer(spacing: 0) {
      composerBody
        .glassEffect(
          .regular
            .tint(Color.white.opacity(0.12))
            .interactive(),
          in: .rect(cornerRadius: 22)
        )
        .scrollEdgeEffectStyle(.soft, for: .bottom)
    }
  }

  private var composerBody: some View {
    VStack(spacing: 10) {
      if let permission = store.currentPermissionRequest(for: sessionID) {
        PermissionPromptCard(
          store: store,
          sessionID: sessionID,
          request: permission
        )
      }

      if let question = store.currentQuestionRequest(for: sessionID) {
        QuestionPromptCard(
          store: store,
          sessionID: sessionID,
          request: question
        )
      }

      let todos = store.todosBySession[sessionID] ?? []
      if !todos.isEmpty {
        TodoDockCard(todos: todos)
      }

      let composerBlocked = store.isComposerBlocked(for: sessionID)
      let isRunning = store.isSessionRunning(sessionID)

      HStack(alignment: .bottom, spacing: 10) {
        TextField("Message", text: $store.draftMessage, axis: .vertical)
          .lineLimit(1 ... 6)
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          .disabled(composerBlocked)
          .accessibilityIdentifier("composer.input")

        Button {
          Task {
            if store.isSessionRunning(sessionID) {
              await store.abort(sessionID: sessionID)
            } else {
              await store.sendDraftMessage(in: sessionID)
            }
          }
        } label: {
          Image(systemName: store.isSessionRunning(sessionID) ? "stop.fill" : "arrow.up")
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 42, height: 42)
            .background(Circle().fill(Color.accentColor))
        }
        .buttonStyle(.plain)
        .disabled(!isRunning && (composerBlocked || store.draftMessage.trimmedForInput.isEmpty))
        .accessibilityIdentifier("composer.sendAbort")
        .accessibilityLabel(store.isSessionRunning(sessionID) ? "Abort" : "Send")
      }

      if composerBlocked {
        Text("Respond to the active prompt before sending another message.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      HStack(spacing: 8) {
        agentMenu

        modelMenu

        effortMenu

        Spacer()

        Text(store.statusLabel(for: sessionID))
          .font(.caption)
          .foregroundStyle(.secondary)
          .accessibilityIdentifier("composer.status")
      }
    }
    .padding(12)
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
        .font(.caption.weight(.semibold))
        .lineLimit(1)
    }
    .accessibilityIdentifier("composer.agentMenu")
    .accessibilityLabel("Agent Menu")
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
        .font(.caption.weight(.semibold))
        .lineLimit(1)
    }
    .accessibilityIdentifier("composer.modelMenu")
    .accessibilityLabel("Model Menu")
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
        .font(.caption.weight(.semibold))
        .lineLimit(1)
    }
    .accessibilityIdentifier("composer.effortMenu")
    .accessibilityLabel("Thinking Effort Menu")
  }
}

#endif
