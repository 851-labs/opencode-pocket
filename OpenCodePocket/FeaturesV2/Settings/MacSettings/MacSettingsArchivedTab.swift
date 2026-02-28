#if os(macOS)
import OpenCodeModels
import SwiftUI

struct MacSettingsArchivedTab: View {
  @Environment(WorkspaceStore.self) private var store
  
  @State private var unarchivingSessionIDs: Set<String> = []
  
  private var archivedThreads: [Session] {
    store.archivedSessions
      .filter { $0.parentID == nil }
  }
  
  var body: some View {
    VStack {
      if archivedThreads.isEmpty {
        ContentUnavailableView(
          "No Archived Threads",
          systemImage: "archivebox",
          description: Text("Archived threads will appear here.")
        )
      } else {
        Form {
          Section {
            ForEach(archivedThreads) { session in
              LabeledContent {
                Button(unarchivingSessionIDs.contains(session.id) ? "Unarchiving..." : "Unarchive") {
                  unarchive(sessionID: session.id)
                }
                .disabled(unarchivingSessionIDs.contains(session.id))
                .accessibilityIdentifier("settings.archived.unarchive.\(session.id)")
              } label: {
                Text(session.title)
                Text(metadata(for: session))
              }
              .padding(.vertical, 4)
              .accessibilityIdentifier("settings.archived.row.\(session.id)")
            }
          } header: {
            if let error = store.latestError, !error.isEmpty {
              HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                  .foregroundStyle(.orange)
                
                Text(error)
                  .font(.callout)
                  .foregroundStyle(.primary)
                
                Spacer(minLength: 0)
                
                Button("Dismiss") {
                  store.clearError()
                }
                .buttonStyle(.borderless)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 10)
              .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
              .padding(.horizontal, -10)
            }
          }
        }
        .formStyle(.grouped)
      }
    }
    .task {
      if store.sessions.isEmpty {
        await store.refreshSessions()
      }
    }
  }
  
  private func metadata(for session: Session) -> String {
    "\(formattedArchivedDate(for: session.time.archived)) • \(store.projectLabel(for: session.directory))"
  }
  
  private func formattedArchivedDate(for rawArchivedTime: Double?) -> String {
    guard let rawArchivedTime else {
      return "Archived"
    }
    
    let seconds = rawArchivedTime > 10_000_000_000 ? rawArchivedTime / 1000 : rawArchivedTime
    let date = Date(timeIntervalSince1970: seconds)
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy, h:mm a"
    return formatter.string(from: date)
  }
  
  private func unarchive(sessionID: String) {
    guard !unarchivingSessionIDs.contains(sessionID) else {
      return
    }
    
    unarchivingSessionIDs.insert(sessionID)
    Task { @MainActor in
      store.clearError()
      await store.unarchiveSession(sessionID: sessionID)
      unarchivingSessionIDs.remove(sessionID)
    }
  }
}

#Preview("Archived") {
  MacSettingsArchivedTab()
    .withMacSettingsArchivedPreviewEnv(.archivedThreads)
    .frame(width: 860, height: 560)
}

#Preview("Archived Empty") {
  MacSettingsArchivedTab()
    .withMacSettingsArchivedPreviewEnv(.noArchivedThreads)
    .frame(width: 860, height: 560)
}

#Preview("Archived Error") {
  MacSettingsArchivedTab()
    .withMacSettingsArchivedPreviewEnv(.archivedThreadsError)
    .frame(width: 860, height: 560)
}
#endif
