import OpenCodeModels
import SwiftUI

struct ChatView: View {
  @Bindable var store: WorkspaceStore
  let sessionID: String

  private var messages: [MessageEnvelope] {
    store.messagesBySession[sessionID] ?? []
  }

  var body: some View {
    VStack(spacing: 0) {
      transcript

      Divider()

      composer

      statusRow
    }
    .navigationTitle(store.sessionTitle(for: sessionID))
    .task(id: sessionID) {
      await store.loadMessages(sessionID: sessionID)
    }
  }

  private var transcript: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 10) {
          ForEach(messages) { message in
            MessageBubble(message: message)
              .id(message.id)
              .accessibilityIdentifier("chat.message.\(message.id)")
          }
        }
        .padding(16)
      }
      .accessibilityIdentifier("chat.messages")
      .onChange(of: messages.count) { _, _ in
        scrollToBottom(using: proxy)
      }
    }
  }

  private var composer: some View {
    HStack(alignment: .bottom, spacing: 8) {
      TextField("Message", text: $store.draftMessage, axis: .vertical)
        .lineLimit(1 ... 6)
        .accessibilityIdentifier("chat.input")

      Button("Send", action: sendMessage)
        .buttonStyle(.borderedProminent)
        .disabled(store.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isSending)
        .accessibilityIdentifier("chat.send")
    }
    .padding(12)
  }

  private var statusRow: some View {
    HStack {
      Button("Abort", action: abortSession)
        .accessibilityIdentifier("chat.abort")

      Spacer()

      Text("Status: \(store.statusLabel(for: sessionID))")
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("chat.status")
    }
    .padding(.horizontal, 12)
    .padding(.bottom, 10)
  }

  private func scrollToBottom(using proxy: ScrollViewProxy) {
    guard let lastID = messages.last?.id else { return }
    withAnimation(.easeOut(duration: 0.2)) {
      proxy.scrollTo(lastID, anchor: .bottom)
    }
  }

  private func sendMessage() {
    Task {
      await store.sendDraftMessage(in: sessionID)
    }
  }

  private func abortSession() {
    Task {
      await store.abort(sessionID: sessionID)
    }
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
        .fill(message.info.role == .assistant ? Color.secondary.opacity(0.15) : Color.accentColor.opacity(0.18))
    )
  }
}
