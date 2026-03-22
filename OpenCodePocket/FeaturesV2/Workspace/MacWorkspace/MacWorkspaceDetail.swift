#if os(macOS)
  import OpenCodeSDK
  import SwiftUI

  struct MacWorkspaceDetail: View {
    let bootstrapState: MacWorkspaceBootstrapState
    let selectedSessionID: String?
    @Binding var selectedPanel: MacWorkspacePanel
    let retry: () -> Void

    @ViewBuilder
    var body: some View {
      switch bootstrapState {
      case .loading:
        MacWorkspaceLoadingView()
      case let .failed(message):
        MacWorkspaceBootstrapErrorView(message: message, retry: retry)
      case .ready:
        MacWorkspaceDetailContent(
          selectedSessionID: selectedSessionID,
          selectedPanel: $selectedPanel
        )
      }
    }
  }

  private struct MacWorkspaceDetailContent: View {
    @Environment(WorkspaceStore.self) private var store

    let selectedSessionID: String?
    @Binding var selectedPanel: MacWorkspacePanel

    @State private var composerHeight: CGFloat = 0

    private var composerBottomInset: CGFloat {
      max(0, composerHeight + 8)
    }

    private var selectedMessages: [MessageEnvelope]? {
      guard let selectedSessionID else {
        return nil
      }
      return store.loadedMessages(for: selectedSessionID)
    }

    private var isInitialTranscriptLoadInProgress: Bool {
      guard let selectedSessionID else {
        return false
      }
      return !store.hasLoadedMessages(for: selectedSessionID) && store.isLoadingMessages(for: selectedSessionID)
    }

    var body: some View {
      ZStack(alignment: .bottom) {
        Group {
          switch selectedPanel {
          case .transcript:
            if let selectedSessionID {
              MacTranscriptPane(
                messages: selectedMessages ?? [],
                isInitialLoadInProgress: isInitialTranscriptLoadInProgress,
                sessionStatus: store.status(for: selectedSessionID),
                showReasoningSummaries: store.showReasoningSummaries,
                expandShellToolParts: store.expandShellToolParts,
                expandEditToolParts: store.expandEditToolParts,
                bottomInset: composerBottomInset
              )
            } else {
              MacNewChatPane(bottomInset: composerBottomInset)
            }
          case .changes:
            if let selectedSessionID {
              MacChangesPane(
                diffs: store.diffs(for: selectedSessionID),
                bottomInset: composerBottomInset
              )
            } else {
              ContentUnavailableView(
                "No Code Changes",
                systemImage: "doc.text.magnifyingglass",
                description: Text("Select a session to view code changes.")
              )
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        MacComposerView(sessionID: selectedSessionID)
          .padding(12)
          .background {
            GeometryReader { proxy in
              Color.clear
                .preference(key: MacComposerHeightPreferenceKey.self, value: proxy.size.height)
            }
          }
      }
      .onPreferenceChange(MacComposerHeightPreferenceKey.self) { value in
        composerHeight = value
      }
    }
  }

  private struct MacComposerHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
      value = max(value, nextValue())
    }
  }

  private struct MacNewChatPane: View {
    @Environment(WorkspaceStore.self) private var store

    let bottomInset: CGFloat

    private var selectedProject: SavedProject? {
      guard let selectedProjectID = store.selectedProjectID else {
        return store.projects.first
      }

      return store.projects.first(where: { $0.id == selectedProjectID }) ?? store.projects.first
    }

    private var projectSymbol: String {
      selectedProject?.symbol?.trimmedNonEmpty ?? "folder"
    }

    private var projectName: String {
      selectedProject?.name ?? "Workspace"
    }

    private var projectDirectory: String {
      selectedProject?.directory ?? store.connection.resolvedDirectory ?? "No directory selected"
    }

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          VStack(alignment: .leading, spacing: 8) {
            Label("New Chat", systemImage: "sparkles")
              .font(.title2.weight(.semibold))

            Text("Start with a clear goal. Your first message creates the session.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }

          VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
              Image(systemName: projectSymbol)
                .font(.headline)
                .frame(width: 30, height: 30)
                .foregroundStyle(Color.accentColor)
                .background(
                  Circle()
                    .fill(Color.accentColor.opacity(0.15))
                )

              VStack(alignment: .leading, spacing: 2) {
                Text(projectName)
                  .font(.headline)

                Text(projectDirectory)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                  .textSelection(.enabled)
              }

              Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
              Label("Ask for a plan before coding.", systemImage: "list.bullet.rectangle")
              Label("Mention files, constraints, and expected output.", systemImage: "doc.text")
              Label("Use the composer below to begin.", systemImage: "arrow.down.circle")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
          }
          .padding(16)
          .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .fill(Color.secondary.opacity(0.08))
          )
        }
        .frame(maxWidth: 760, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, max(24, bottomInset + 8))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(
        LinearGradient(
          colors: [Color.accentColor.opacity(0.06), Color.clear],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .accessibilityIdentifier("workspace.newChat.pane")
    }
  }

  private struct MacChangesPane: View {
    let diffs: [FileDiff]
    let bottomInset: CGFloat

    var body: some View {
      if diffs.isEmpty {
        ContentUnavailableView(
          "No Code Changes",
          systemImage: "doc.text.magnifyingglass",
          description: Text("Run a coding task to populate this diff view.")
        )
      } else {
        List {
          ForEach(diffs) { diff in
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 4) {
                Text(diff.file)
                  .font(.subheadline.weight(.semibold))
                  .lineLimit(2)
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

          Color.clear
            .frame(height: max(0, bottomInset))
            .listRowInsets(.init())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.inset)
      }
    }
  }

  #Preview("Detail - Loading") {
    @Previewable @State var selectedPanel: MacWorkspacePanel = .transcript

    MacWorkspaceDetail(
      bootstrapState: .loading,
      selectedSessionID: nil,
      selectedPanel: $selectedPanel,
      retry: {}
    )
    .frame(minWidth: 900, minHeight: 700)
  }

  #Preview("Detail - Error") {
    @Previewable @State var selectedPanel: MacWorkspacePanel = .transcript

    MacWorkspaceDetail(
      bootstrapState: .failed("Connection timed out"),
      selectedSessionID: nil,
      selectedPanel: $selectedPanel,
      retry: {}
    )
    .frame(minWidth: 900, minHeight: 700)
  }

  #Preview("Detail - Transcript", traits: .macWorkspace) {
    MacWorkspaceDetailPreviewHost(initialPanel: .transcript)
      .frame(minWidth: 900, minHeight: 700)
  }

  #Preview("Detail - Changes", traits: .macWorkspace) {
    MacWorkspaceDetailPreviewHost(initialPanel: .changes)
      .frame(minWidth: 900, minHeight: 700)
  }

  private struct MacWorkspaceDetailPreviewHost: View {
    @Environment(WorkspaceStore.self) private var store

    @State private var selectedPanel: MacWorkspacePanel

    init(initialPanel: MacWorkspacePanel) {
      _selectedPanel = State(initialValue: initialPanel)
    }

    var body: some View {
      MacWorkspaceDetail(
        bootstrapState: .ready,
        selectedSessionID: store.selectedSessionID ?? store.visibleSessions.first?.id,
        selectedPanel: $selectedPanel,
        retry: {}
      )
    }
  }

#endif
