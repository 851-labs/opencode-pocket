#if os(macOS)
import OpenCodeModels
import SwiftUI

struct MacTranscriptPane: View {
  let messages: [MessageEnvelope]
  let sessionStatus: SessionStatus
  let showReasoningSummaries: Bool

  @State private var followTail = true
  @State private var hasPendingTail = false
  @State private var visibleTurnLimit = 40

  private let turnBatchSize = 40

  private var turns: [MacTranscriptTurn] {
    MacTranscriptTurn.build(from: messages)
  }

  private var visibleTurns: [MacTranscriptTurn] {
    Array(turns.suffix(visibleTurnLimit))
  }

  private var hiddenTurnCount: Int {
    max(0, turns.count - visibleTurnLimit)
  }

  var body: some View {
    if turns.isEmpty {
      ContentUnavailableView(
        "No Messages Yet",
        systemImage: "text.bubble",
        description: Text("Send a message to start this session.")
      )
    } else {
      ScrollViewReader { proxy in
        ZStack(alignment: .bottomTrailing) {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
              if hiddenTurnCount > 0 {
                Button {
                  visibleTurnLimit += turnBatchSize
                  followTail = false
                } label: {
                  Text("Load earlier (\(hiddenTurnCount))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("workspace.transcript.loadEarlier")
              }

              ForEach(Array(visibleTurns.enumerated()), id: \.element.id) { index, turn in
                MacTurnView(
                  turn: turn,
                  isWorking: index == visibleTurns.count - 1 && sessionStatus.isRunning,
                  showReasoningSummaries: showReasoningSummaries
                )
                .id(turn.id)
              }
            }
            .padding(16)
          }
          .simultaneousGesture(
            DragGesture(minimumDistance: 8)
              .onChanged { value in
                if value.translation.height > 16 {
                  followTail = false
                }
              }
          )
          .onChange(of: messages.count) { _, _ in
            visibleTurnLimit = max(visibleTurnLimit, turnBatchSize)
            guard let lastID = turns.last?.id else { return }
            if followTail {
              withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastID, anchor: .bottom)
              }
              hasPendingTail = false
              return
            }
            hasPendingTail = true
          }
          .onChange(of: followTail) { _, shouldFollow in
            guard shouldFollow, let lastID = turns.last?.id else {
              return
            }
            withAnimation(.easeOut(duration: 0.2)) {
              proxy.scrollTo(lastID, anchor: .bottom)
            }
            hasPendingTail = false
          }

          if hasPendingTail {
            Button {
              followTail = true
            } label: {
              Label("Jump to latest", systemImage: "arrow.down.circle.fill")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .foregroundStyle(.white)
                .background(
                  Capsule(style: .continuous)
                    .fill(Color.accentColor)
                )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
            .padding(.bottom, 14)
            .accessibilityIdentifier("workspace.transcript.resume")
          }
        }
      }
    }
  }
}

struct MacTranscriptTurn: Identifiable {
  let id: String
  let user: MessageEnvelope?
  let assistantMessages: [MessageEnvelope]

  static func build(from messages: [MessageEnvelope]) -> [MacTranscriptTurn] {
    var turns: [MacTranscriptTurn] = []
    var index = 0

    while index < messages.count {
      let current = messages[index]

      if current.info.role == .user {
        var assistants: [MessageEnvelope] = []
        var scan = index + 1

        while scan < messages.count {
          let next = messages[scan]
          if next.info.role == .user {
            break
          }

          if next.info.role == .assistant {
            if let parentID = next.info.parentID {
              if parentID == current.id {
                assistants.append(next)
              }
            } else {
              assistants.append(next)
            }
          }

          scan += 1
        }

        turns.append(MacTranscriptTurn(id: current.id, user: current, assistantMessages: assistants))
        index = scan
        continue
      }

      if current.info.role == .assistant {
        turns.append(MacTranscriptTurn(id: current.id, user: nil, assistantMessages: [current]))
      }

      index += 1
    }

    return turns
  }
}

private struct MacTurnView: View {
  let turn: MacTranscriptTurn
  let isWorking: Bool
  let showReasoningSummaries: Bool

  private var latestReasoningHeading: String? {
    turn.assistantMessages
      .flatMap(\.parts)
      .filter { $0.type == "reasoning" }
      .compactMap { $0.text }
      .compactMap(macExtractReasoningHeading)
      .last
  }

  private var hasVisibleAssistantText: Bool {
    turn.assistantMessages
      .flatMap(\.parts)
      .contains { $0.type == "text" && !($0.text?.trimmedForInput ?? "").isEmpty }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let user = turn.user {
        MacUserMessageCard(message: user)
      }

      ForEach(Array(turn.assistantMessages.enumerated()), id: \.element.id) { index, assistant in
        MacAssistantMessageCard(
          message: assistant,
          busy: isWorking && index == turn.assistantMessages.count - 1,
          showReasoningSummaries: showReasoningSummaries
        )
      }

      if isWorking && (!hasVisibleAssistantText || showReasoningSummaries || latestReasoningHeading != nil) {
        HStack(spacing: 8) {
          ProgressView()
            .controlSize(.small)
          Text("Thinking...")
            .font(.caption)
            .foregroundStyle(.secondary)

          if !showReasoningSummaries, let latestReasoningHeading {
            Text(latestReasoningHeading)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        .padding(.leading, 8)
      }

      if
        let user = turn.user,
        !user.info.summaryDiffs.isEmpty,
        !isWorking
      {
        MacTurnDiffSummaryCard(diffs: user.info.summaryDiffs)
      }
    }
  }
}
#endif
