import OpenCodeModels
import SwiftUI

struct SessionsView: View {
  @Environment(WorkspaceStore.self) private var store

  var body: some View {
    @Bindable var store = store

    List(selection: $store.selectedSessionID) {
      sessionsList
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
      toolbarContent
    }
    .onChange(of: store.selectedSessionID) { _, newValue in
      selectSession(newValue)
    }
  }

  @ViewBuilder
  private var sessionsList: some View {
    ForEach(store.sessions) { session in
      SessionRow(session: session)
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarTrailing) {
      Button(action: refreshSessions) {
        if store.isRefreshingSessions {
          ProgressView()
            .controlSize(.small)
        } else {
          Image(systemName: "arrow.clockwise")
        }
      }
      .disabled(store.isRefreshingSessions)
      .accessibilityIdentifier("sessions.refresh")

      Button(action: createSession) {
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

  private func refreshSessions() {
    Task {
      await store.refreshSessions()
    }
  }

  private func createSession() {
    store.beginNewSession()
  }

  private func selectSession(_ sessionID: String?) {
    Task {
      await store.selectSession(sessionID)
    }
  }
}

private struct SessionRow: View {
  @Environment(WorkspaceStore.self) private var store
  let session: Session

  private var title: String {
    session.title.isEmpty ? "Untitled Session" : session.title
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
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
