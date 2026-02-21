#if os(macOS)
import OpenCodeModels
import SwiftUI

private enum MacWorkspacePanel: String, CaseIterable, Identifiable {
  case transcript = "Transcript"
  case changes = "Changes"

  var id: Self { self }
}

struct MacWorkspaceView: View {
  @Bindable var store: AppStore

  @State private var selectedPanel: MacWorkspacePanel = .transcript
  @State private var isRenameSheetPresented = false
  @State private var isDeleteConfirmationPresented = false
  @State private var renameDraft = ""

  private var selectedSessionID: String? {
    store.selectedSessionID
  }

  var body: some View {
    NavigationSplitView {
      sidebar
    } detail: {
      detail
    }
    .navigationSplitViewStyle(.balanced)
    .task {
      await store.refreshAgentAndModelOptions()
      await store.refreshSessions()
    }
    .onChange(of: store.selectedSessionID) { _, newValue in
      Task {
        await store.selectSession(newValue)
      }
    }
    .sheet(isPresented: $isRenameSheetPresented) {
      renameSheet
    }
    .confirmationDialog("Delete Session?", isPresented: $isDeleteConfirmationPresented) {
      Button("Delete", role: .destructive) {
        deleteSelectedSession()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This permanently removes the selected chat session.")
    }
    .toolbar {
      toolbarContent
    }
  }

  private var sidebar: some View {
    List(selection: $store.selectedSessionID) {
      ForEach(store.visibleSessions) { session in
        VStack(alignment: .leading, spacing: 4) {
          Text(session.title)
            .font(.body.weight(.semibold))
            .lineLimit(1)

          HStack(spacing: 6) {
            Text(session.id)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)

            Circle()
              .fill(.secondary.opacity(0.5))
              .frame(width: 3, height: 3)

            Text(store.statusLabel(for: session.id))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .tag(session.id as String?)
      }
    }
    .navigationTitle("Sessions")
    .overlay {
      if store.visibleSessions.isEmpty {
        ContentUnavailableView(
          "No Sessions",
          systemImage: "tray",
          description: Text("Create a session to start chatting with your OpenCode server.")
        )
      }
    }
  }

  @ViewBuilder
  private var detail: some View {
    if let selectedSessionID {
      VStack(spacing: 0) {
        HStack(spacing: 12) {
          Text(store.sessionTitle(for: selectedSessionID))
            .font(.title3.weight(.semibold))
            .lineLimit(1)

          Spacer(minLength: 0)

          Picker("Panel", selection: $selectedPanel) {
            ForEach(MacWorkspacePanel.allCases) { panel in
              Text(panel.rawValue).tag(panel)
            }
          }
          .pickerStyle(.segmented)
          .frame(width: 220)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)

        Divider()

        Group {
          switch selectedPanel {
          case .transcript:
            MacTranscriptPane(messages: store.messagesBySession[selectedSessionID] ?? [])
          case .changes:
            MacChangesPane(diffs: store.diffsBySession[selectedSessionID] ?? [])
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        Divider()

        MacComposerView(store: store, sessionID: selectedSessionID)
          .padding(12)
      }
    } else {
      ContentUnavailableView(
        "No Session Selected",
        systemImage: "bubble.left.and.bubble.right",
        description: Text("Select or create a session from the sidebar.")
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItemGroup {
      Button {
        Task {
          await store.refreshSessions()
        }
      } label: {
        if store.isRefreshingSessions {
          ProgressView()
            .controlSize(.small)
        } else {
          Image(systemName: "arrow.clockwise")
        }
      }
      .disabled(store.isRefreshingSessions)
      .accessibilityIdentifier("sessions.refresh")

      Button {
        Task {
          await store.createSession()
        }
      } label: {
        if store.isCreatingSession {
          ProgressView()
            .controlSize(.small)
        } else {
          Image(systemName: "plus")
        }
      }
      .disabled(store.isCreatingSession)
      .accessibilityIdentifier("sessions.create")
    }

    ToolbarItem {
      Button("Disconnect") {
        store.disconnect()
      }
      .accessibilityIdentifier("sessions.disconnect")
    }

    ToolbarItem(placement: .primaryAction) {
      Menu {
        Button("Rename") {
          prepareRenameSession()
        }
        .disabled(selectedSessionID == nil)

        Button("Archive") {
          archiveSelectedSession()
        }
        .disabled(selectedSessionID == nil)

        Button("Delete", role: .destructive) {
          isDeleteConfirmationPresented = true
        }
        .disabled(selectedSessionID == nil)
      } label: {
        Label("Session Actions", systemImage: "ellipsis.circle")
      }
      .accessibilityIdentifier("workspace.actions.menu")
    }
  }

  private var renameSheet: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Rename Session")
        .font(.headline)

      TextField("Session title", text: $renameDraft)

      HStack {
        Spacer()

        Button("Cancel") {
          isRenameSheetPresented = false
        }

        Button("Save") {
          saveRename()
          isRenameSheetPresented = false
        }
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(18)
    .frame(width: 360)
  }

  private func prepareRenameSession() {
    guard let selectedSessionID else { return }
    renameDraft = store.sessionTitle(for: selectedSessionID)
    isRenameSheetPresented = true
  }

  private func archiveSelectedSession() {
    guard let selectedSessionID else { return }
    Task {
      await store.archiveSession(sessionID: selectedSessionID)
    }
  }

  private func deleteSelectedSession() {
    guard let selectedSessionID else { return }
    Task {
      await store.deleteSession(sessionID: selectedSessionID)
    }
  }

  private func saveRename() {
    guard let selectedSessionID else { return }
    Task {
      await store.renameSession(sessionID: selectedSessionID, title: renameDraft)
    }
  }
}

private struct MacTranscriptPane: View {
  let messages: [MessageEnvelope]

  var body: some View {
    if messages.isEmpty {
      ContentUnavailableView(
        "No Messages Yet",
        systemImage: "text.bubble",
        description: Text("Send a message to start this session.")
      )
    } else {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 10) {
          ForEach(messages) { message in
            VStack(alignment: .leading, spacing: 6) {
              Text(message.info.role == .assistant ? "Assistant" : "You")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

              Text(message.textBody)
                .font(.body)
                .textSelection(.enabled)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
              RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(message.info.role == .assistant ? Color.gray.opacity(0.12) : Color.accentColor.opacity(0.16))
            )
          }
        }
        .padding(16)
      }
    }
  }
}

private struct MacChangesPane: View {
  let diffs: [FileDiff]

  var body: some View {
    if diffs.isEmpty {
      ContentUnavailableView(
        "No Code Changes",
        systemImage: "doc.text.magnifyingglass",
        description: Text("Run a coding task to populate this diff view.")
      )
    } else {
      List(diffs) { diff in
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 4) {
            Text(diff.file)
              .font(.subheadline.weight(.semibold))
            Text(diff.status?.capitalized ?? "Modified")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()

          VStack(alignment: .trailing, spacing: 2) {
            Text("+\(diff.additionsCount)")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.green)
            Text("-\(diff.deletionsCount)")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.red)
          }
        }
        .padding(.vertical, 2)
      }
      .listStyle(.inset)
    }
  }
}

private struct MacComposerView: View {
  @Bindable var store: AppStore
  let sessionID: String

  var body: some View {
    VStack(spacing: 10) {
      TextField("Message", text: $store.draftMessage, axis: .vertical)
        .lineLimit(1 ... 8)

      HStack(spacing: 10) {
        agentMenu

        modelMenu

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
        .disabled(!store.isSessionRunning(sessionID) && store.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                  Label(model.displayLabel, systemImage: "checkmark")
                } else {
                  Text(model.displayLabel)
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
}
#endif
