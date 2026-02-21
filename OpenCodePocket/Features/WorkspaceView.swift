import SwiftUI
import OpenCodeModels

private enum WorkspacePanel: String, CaseIterable, Identifiable {
  case session = "Session"
  case changes = "Changes"

  var id: Self { self }
}

struct WorkspaceView: View {
  @Bindable var store: AppStore

  @State private var selectedPanel: WorkspacePanel = .session
  @State private var isDrawerPresented = false
  @State private var isRenamePromptPresented = false
  @State private var isDeleteConfirmationPresented = false
  @State private var renameDraft = ""

  private var selectedSessionID: String? {
    store.selectedSessionID
  }

  var body: some View {
    NavigationStack {
      workspaceRoot
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: isDrawerPresented)
        .task {
          await store.refreshAgentAndModelOptions()
          await store.refreshSessions()
        }
        .alert("Rename Session", isPresented: $isRenamePromptPresented) {
          TextField("Session title", text: $renameDraft)
          Button("Cancel", role: .cancel) {}
          Button("Save") {
            saveRename()
          }
        }
        .alert("Delete Session?", isPresented: $isDeleteConfirmationPresented) {
          Button("Cancel", role: .cancel) {}
          Button("Delete", role: .destructive) {
            deleteSelectedSession()
          }
        } message: {
          Text("This permanently removes the selected chat session.")
        }
    }
  }

  @ViewBuilder
  private var content: some View {
    if let selectedSessionID {
      switch selectedPanel {
      case .session:
        SessionTranscriptPane(messages: store.messagesBySession[selectedSessionID] ?? [])
          .accessibilityIdentifier("workspace.session.pane")
      case .changes:
        ChangesPane(diffs: store.diffsBySession[selectedSessionID] ?? [])
          .accessibilityIdentifier("workspace.changes.pane")
      }
    } else {
      ContentUnavailableView(
        "No Session Selected",
        systemImage: "bubble.left.and.bubble.right",
        description: Text("Open sessions and choose a session.")
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

// MARK: - Subviews

private extension WorkspaceView {
  var workspaceRoot: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(red: 0.93, green: 0.95, blue: 0.99),
          Color(red: 0.96, green: 0.98, blue: 0.97),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      content
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      workspaceToolbar
    }
    .sheet(isPresented: $isDrawerPresented) {
      SessionSheet(store: store, isPresented: $isDrawerPresented)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("workspace.drawer")
    }
    .safeAreaInset(edge: .bottom) {
      if let selectedSessionID {
        WorkspaceComposer(store: store, sessionID: selectedSessionID)
          .padding(.horizontal, 14)
          .padding(.bottom, 8)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
  }

  @ToolbarContentBuilder
  var workspaceToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button {
        toggleDrawer()
      } label: {
        Image(systemName: "line.3.horizontal")
          .font(.headline)
          .frame(width: 36, height: 36)
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("workspace.drawer.toggle")
    }

    ToolbarItem(placement: .principal) {
      Picker("Panel", selection: $selectedPanel) {
        ForEach(WorkspacePanel.allCases) { panel in
          Text(panel.rawValue).tag(panel)
        }
      }
      .pickerStyle(.segmented)
      .frame(maxWidth: 220)
      .accessibilityIdentifier("workspace.panel.picker")
    }

    ToolbarItem(placement: .topBarTrailing) {
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
          confirmDeleteSession()
        }
        .disabled(selectedSessionID == nil)
      } label: {
        Image(systemName: "ellipsis")
          .font(.headline)
          .frame(width: 36, height: 36)
      }
      .accessibilityIdentifier("workspace.actions.menu")
    }
  }
}

// MARK: - Actions

private extension WorkspaceView {
  func toggleDrawer() {
    isDrawerPresented.toggle()
  }

  func prepareRenameSession() {
    guard let selectedSessionID else { return }
    renameDraft = store.sessionTitle(for: selectedSessionID)
    isRenamePromptPresented = true
  }

  func archiveSelectedSession() {
    guard let selectedSessionID else { return }
    Task {
      await store.archiveSession(sessionID: selectedSessionID)
    }
  }

  func confirmDeleteSession() {
    guard selectedSessionID != nil else { return }
    isDeleteConfirmationPresented = true
  }

  func saveRename() {
    guard let selectedSessionID else { return }
    Task {
      await store.renameSession(sessionID: selectedSessionID, title: renameDraft)
    }
  }

  func deleteSelectedSession() {
    guard let selectedSessionID else { return }
    Task {
      await store.deleteSession(sessionID: selectedSessionID)
    }
  }
}

private struct SessionSheet: View {
  @Bindable var store: AppStore
  @Binding var isPresented: Bool

  var body: some View {
    NavigationStack {
      List {
        Section("Actions") {
          Button {
            Task {
              await store.refreshSessions()
            }
          } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
          }
          .accessibilityIdentifier("drawer.refresh")

          Button {
            Task {
              await store.createSession()
            }
          } label: {
            Label("New Session", systemImage: "plus")
          }
          .accessibilityIdentifier("drawer.create")
        }

        Section("Sessions") {
          ForEach(store.visibleSessions) { session in
            Button {
              Task {
                await store.selectSession(session.id)
                isPresented = false
              }
            } label: {
              HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                  Text(session.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                  HStack(spacing: 6) {
                    Text(session.id)
                      .font(.caption)
                      .lineLimit(1)
                      .foregroundStyle(.secondary)

                    Circle()
                      .fill(Color.secondary.opacity(0.6))
                      .frame(width: 3, height: 3)

                    Text(store.statusLabel(for: session.id))
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                }

                Spacer()

                if store.selectedSessionID == session.id {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                }
              }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("drawer.session.\(session.id)")
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("Sessions")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            isPresented = false
          }
        }
      }
      .accessibilityIdentifier("workspace.drawer")
    }
  }
}

private struct SessionTranscriptPane: View {
  let messages: [MessageEnvelope]

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 12) {
          if messages.isEmpty {
            ContentUnavailableView(
              "No Messages Yet",
              systemImage: "text.bubble",
              description: Text("Send a message to start this session.")
            )
            .frame(maxWidth: .infinity, minHeight: 320)
          } else {
            ForEach(messages) { message in
              MessageBubble(message: message)
                .id(message.id)
                .accessibilityIdentifier("workspace.message.\(message.id)")
            }
          }
        }
        .padding(16)
      }
      .onChange(of: messages.count) { _, _ in
        guard let lastID = messages.last?.id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
          proxy.scrollTo(lastID, anchor: .bottom)
        }
      }
    }
  }
}

private struct ChangesPane: View {
  let diffs: [FileDiff]

  var body: some View {
    if diffs.isEmpty {
      ContentUnavailableView(
        "No Code Changes",
        systemImage: "doc.text.magnifyingglass",
        description: Text("Run a coding task to populate this diff view.")
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .accessibilityIdentifier("changes.empty")
    } else {
      ScrollView {
        LazyVStack(spacing: 10) {
          ForEach(diffs) { diff in
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 6) {
                Text(diff.file)
                  .font(.subheadline.weight(.semibold))
                  .lineLimit(2)

                Text(diff.status?.capitalized ?? "Modified")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }

              Spacer()

              VStack(alignment: .trailing, spacing: 4) {
                Text("+\(diff.additionsCount)")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.green)

                Text("-\(diff.deletionsCount)")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.red)
              }
            }
            .padding(12)
            .background(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.72))
            )
            .accessibilityIdentifier("changes.row.\(diff.id)")
          }
        }
        .padding(16)
      }
      .accessibilityIdentifier("changes.list")
    }
  }
}

private struct WorkspaceComposer: View {
  @Bindable var store: AppStore
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
      HStack(alignment: .bottom, spacing: 10) {
        TextField("Message", text: $store.draftMessage, axis: .vertical)
          .lineLimit(1 ... 6)
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
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
        .disabled(!store.isSessionRunning(sessionID) && store.draftMessage.trimmedForInput.isEmpty)
        .accessibilityIdentifier("composer.sendAbort")
        .accessibilityLabel(store.isSessionRunning(sessionID) ? "Abort" : "Send")
      }

      HStack(spacing: 8) {
        agentMenu

        modelMenu

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
        .font(.caption.weight(.semibold))
        .lineLimit(1)
    }
    .accessibilityIdentifier("composer.modelMenu")
    .accessibilityLabel("Model Menu")
  }
}

private struct MessageBubble: View {
  let message: MessageEnvelope

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(message.info.role == .assistant ? "Assistant" : "You")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      Text(message.textBody)
        .font(.body)
        .textSelection(.enabled)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: message.info.role == .assistant ? .leading : .trailing)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(message.info.role == .assistant ? Color.white.opacity(0.72) : Color.accentColor.opacity(0.18))
    )
  }
}

private extension String {
  var trimmedForInput: String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
