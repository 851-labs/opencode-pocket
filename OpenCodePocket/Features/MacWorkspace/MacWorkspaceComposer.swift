#if os(macOS)
  import SwiftUI

  struct MacComposerView: View {
    @Bindable var store: WorkspaceStore
    let sessionID: String

    var body: some View {
      VStack(spacing: 10) {
        promptCards

        composerSurface
      }
    }

    @ViewBuilder
    private var promptCards: some View {
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
    }

    private var composerSurface: some View {
      composerCard
    }

    private var composerCard: some View {
      let composerBlocked = store.isComposerBlocked(for: sessionID)
      let isRunning = store.isSessionRunning(sessionID)

      return VStack(alignment: .leading, spacing: 10) {
        composerInputField(composerBlocked: composerBlocked)

        if composerBlocked {
          Text("Respond to the active prompt before sending another message.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        composerControlsRow(composerBlocked: composerBlocked, isRunning: isRunning)
      }
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(Color.white.opacity(0.08))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .strokeBorder(Color.white.opacity(0.24), lineWidth: 0.6)
      )
      .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
      .glassEffect(
        .regular
          .tint(Color.white.opacity(0.12))
          .interactive(),
        in: .rect(cornerRadius: 24)
      )
    }

    private func composerInputField(composerBlocked: Bool) -> some View {
      TextField("Message", text: $store.draftMessage, axis: .vertical)
        .lineLimit(1 ... 8)
        .textFieldStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.18))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.5)
        )
        .disabled(composerBlocked)
        .accessibilityIdentifier("composer.input")
    }

    private func composerControlsRow(composerBlocked: Bool, isRunning: Bool) -> some View {
      HStack(spacing: 8) {
        agentMenu

        modelMenu

        effortMenu

        Spacer(minLength: 6)

        sendButton(composerBlocked: composerBlocked, isRunning: isRunning)
      }
    }

    private func sendButton(composerBlocked: Bool, isRunning: Bool) -> some View {
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
          .font(.subheadline.weight(.bold))
          .foregroundStyle(.white)
          .frame(width: 34, height: 34)
          .background(Circle().fill(Color.accentColor))
      }
      .buttonStyle(.plain)
      .disabled(!isRunning && (composerBlocked || store.draftMessage.trimmedForInput.isEmpty))
      .keyboardShortcut(.defaultAction)
      .accessibilityIdentifier("composer.sendAbort")
      .accessibilityLabel(store.isSessionRunning(sessionID) ? "Abort" : "Send")
    }

    private func menuChipLabel(_ title: String, systemImage: String) -> some View {
      HStack(spacing: 6) {
        Image(systemName: systemImage)
          .font(.caption2.weight(.semibold))

        Text(title)
          .lineLimit(1)

        Image(systemName: "chevron.down")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      .font(.caption.weight(.semibold))
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(
        Capsule(style: .continuous)
          .fill(Color.white.opacity(0.14))
      )
      .overlay(
        Capsule(style: .continuous)
          .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
      )
      .glassEffect(.regular.interactive(), in: .capsule)
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
        menuChipLabel(store.selectedAgentName.capitalized, systemImage: "wand.and.stars")
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
        menuChipLabel(store.selectedModelDisplayName, systemImage: "cpu")
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
        menuChipLabel(store.selectedModelVariantDisplayName, systemImage: "brain")
      }
      .accessibilityIdentifier("composer.effortMenu")
      .accessibilityLabel("Thinking Effort Menu")
    }
  }
#endif
