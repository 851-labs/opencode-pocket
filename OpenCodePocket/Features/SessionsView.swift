import SwiftUI

struct SessionsView: View {
  @Bindable var store: AppStore

  var body: some View {
    List(selection: $store.selectedSessionID) {
      ForEach(store.sessions) { session in
        VStack(alignment: .leading, spacing: 4) {
          Text(session.title.isEmpty ? "Untitled Session" : session.title)
            .font(.body)
            .lineLimit(1)

          HStack(spacing: 6) {
            Text(session.id)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)

            Text("•")
              .font(.caption)
              .foregroundStyle(.secondary)

            Text(store.statusLabel(for: session.id))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .tag(session.id)
        .accessibilityIdentifier("session.row.\(session.id)")
      }
    }
    .accessibilityIdentifier("sessions.list")
    .overlay {
      if store.sessions.isEmpty {
        ContentUnavailableView(
          "No Sessions",
          systemImage: "tray",
          description: Text("Create a session to start chatting with your OpenCode server.")
        )
      }
    }
    .navigationTitle("Sessions")
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
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

      ToolbarItem(placement: .topBarLeading) {
        Button("Disconnect") {
          store.disconnect()
        }
        .accessibilityIdentifier("sessions.disconnect")
      }
    }
    .onChange(of: store.selectedSessionID) { _, newValue in
      Task {
        await store.selectSession(newValue)
      }
    }
  }
}
