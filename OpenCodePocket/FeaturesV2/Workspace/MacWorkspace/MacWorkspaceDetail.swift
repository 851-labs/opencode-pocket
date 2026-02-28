#if os(macOS)
  import OpenCodeModels
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
        if let selectedSessionID {
          MacWorkspaceDetailContent(
            selectedSessionID: selectedSessionID,
            selectedPanel: $selectedPanel
          )
        } else {
          ContentUnavailableView(
            "No Session Selected",
            systemImage: "bubble.left.and.bubble.right",
            description: Text("Select or create a session from the sidebar.")
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
    }
  }

  private struct MacWorkspaceDetailContent: View {
    @Environment(WorkspaceStore.self) private var store

    let selectedSessionID: String
    @Binding var selectedPanel: MacWorkspacePanel

    @State private var composerHeight: CGFloat = 0

    private var composerBottomInset: CGFloat {
      max(0, composerHeight + 8)
    }

    private var selectedMessages: [MessageEnvelope]? {
      store.loadedMessages(for: selectedSessionID)
    }

    private var isInitialTranscriptLoadInProgress: Bool {
      !store.hasLoadedMessages(for: selectedSessionID) && store.isLoadingMessages(for: selectedSessionID)
    }

    var body: some View {
      ZStack(alignment: .bottom) {
        Group {
          switch selectedPanel {
          case .transcript:
            MacTranscriptPane(
              messages: selectedMessages ?? [],
              isInitialLoadInProgress: isInitialTranscriptLoadInProgress,
              sessionStatus: store.status(for: selectedSessionID),
              showReasoningSummaries: store.showReasoningSummaries,
              expandShellToolParts: store.expandShellToolParts,
              expandEditToolParts: store.expandEditToolParts,
              bottomInset: composerBottomInset
            )
          case .changes:
            MacChangesPane(
              diffs: store.diffs(for: selectedSessionID),
              bottomInset: composerBottomInset
            )
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
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
      value = max(value, nextValue())
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
    MacWorkspaceDetail(
      bootstrapState: .loading,
      selectedSessionID: nil,
      selectedPanel: .constant(.transcript),
      retry: {}
    )
    .frame(minWidth: 900, minHeight: 700)
  }

  #Preview("Detail - Error") {
    MacWorkspaceDetail(
      bootstrapState: .failed("Connection timed out"),
      selectedSessionID: nil,
      selectedPanel: .constant(.transcript),
      retry: {}
    )
    .frame(minWidth: 900, minHeight: 700)
  }

  #Preview("Detail - Transcript") {
    MacWorkspaceDetailPreviewHost(initialPanel: .transcript)
      .withMacWorkspacePreviewEnv()
      .frame(minWidth: 900, minHeight: 700)
  }

  #Preview("Detail - Changes") {
    MacWorkspaceDetailPreviewHost(initialPanel: .changes)
      .withMacWorkspacePreviewEnv()
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
