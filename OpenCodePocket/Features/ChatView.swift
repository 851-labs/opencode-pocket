import SwiftUI

struct ChatView: View {
    @Bindable var store: AppStore
    let sessionID: String

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(store.messagesBySession[sessionID] ?? []) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: store.messagesBySession[sessionID]?.count ?? 0) { _, _ in
                    guard let lastID = store.messagesBySession[sessionID]?.last?.id else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Message", text: $store.draftMessage, axis: .vertical)
                    .lineLimit(1...6)

                Button("Send") {
                    Task {
                        await store.sendDraftMessage(in: sessionID)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isSending)
            }
            .padding(12)

            HStack {
                Button("Abort") {
                    Task {
                        await store.abort(sessionID: sessionID)
                    }
                }

                Spacer()

                Text("Status: \(store.statusLabel(for: sessionID))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .navigationTitle(store.sessionTitle(for: sessionID))
        .task(id: sessionID) {
            await store.loadMessages(sessionID: sessionID)
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
