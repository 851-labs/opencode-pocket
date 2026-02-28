import OpenCodeModels
import SwiftUI

enum WorkspaceSessionInspectorSectionID: Hashable {
  case context
  case mcp
  case lsp
  case todo
  case diff
}

enum WorkspaceSessionInspectorBootstrapState {
  case loading
  case ready
  case failed(String)
}

struct WorkspaceSessionInspectorMCPEntry: Hashable, Identifiable {
  let name: String
  let status: MCPServerStatus

  var id: String {
    name
  }
}

struct WorkspaceSessionInspector: View {
  @Environment(WorkspaceStore.self) private var store

  let bootstrapState: WorkspaceSessionInspectorBootstrapState
  let selectedSessionID: String?

  @State private var expandedSections: Set<WorkspaceSessionInspectorSectionID> = [.context, .mcp, .lsp, .todo, .diff]

  private var contextMetrics: SessionInspectorContextMetrics {
    guard let selectedSessionID else {
      return SessionInspectorContextMetrics(tokenCount: 0, percentageUsed: nil, cost: 0)
    }
    return store.inspectorContextMetrics(for: selectedSessionID)
  }

  private var mcpEntries: [WorkspaceSessionInspectorMCPEntry] {
    store.mcpStatuses.keys.sorted().compactMap { name in
      guard let status = store.mcpStatuses[name] else {
        return nil
      }
      return WorkspaceSessionInspectorMCPEntry(name: name, status: status)
    }
  }

  private var lspEntries: [LSPServerStatus] {
    store.lspStatuses
  }

  private var todoItems: [TodoItem] {
    guard let selectedSessionID else {
      return []
    }
    return store.todos(for: selectedSessionID)
  }

  private var shouldShowTodoSection: Bool {
    !todoItems.isEmpty && todoItems.contains(where: { $0.status != "completed" })
  }

  private var diffItems: [FileDiff] {
    guard let selectedSessionID else {
      return []
    }
    return store.diffs(for: selectedSessionID)
  }

  private var connectedMCPCount: Int {
    mcpEntries.filter { $0.status.status == .connected }.count
  }

  private var errorMCPCount: Int {
    mcpEntries.filter {
      switch $0.status.status {
      case .failed, .needsAuth, .needsClientRegistration:
        return true
      default:
        return false
      }
    }.count
  }

  private var mcpCollapsedSummary: String {
    guard errorMCPCount > 0 else {
      return "\(connectedMCPCount) active"
    }
    let suffix = errorMCPCount == 1 ? "error" : "errors"
    return "\(connectedMCPCount) active, \(errorMCPCount) \(suffix)"
  }

  var body: some View {
    content
      .frame(maxHeight: .infinity)
      .background(Color.secondary.opacity(0.04))
      .accessibilityIdentifier("workspace.inspector")
  }

  @ViewBuilder
  private var content: some View {
    switch bootstrapState {
    case .loading:
      VStack(spacing: 8) {
        ProgressView()
        Text("Loading inspector...")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

    case let .failed(message):
      ContentUnavailableView(
        "Inspector Unavailable",
        systemImage: "exclamationmark.triangle",
        description: Text(message)
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)

    case .ready:
      if selectedSessionID != nil {
        Form {
          WorkspaceSessionInspectorContextSection(
            metrics: contextMetrics,
            isExpanded: sectionExpansionBinding(for: .context)
          )

          if !mcpEntries.isEmpty {
            WorkspaceSessionInspectorMCPSection(
              entries: mcpEntries,
              collapsedSummary: mcpCollapsedSummary,
              isExpanded: sectionExpansionBinding(for: .mcp)
            )
          }

          WorkspaceSessionInspectorLSPSection(
            entries: lspEntries,
            isExpanded: sectionExpansionBinding(for: .lsp)
          )

          if shouldShowTodoSection {
            WorkspaceSessionInspectorTodoSection(
              items: todoItems,
              isExpanded: sectionExpansionBinding(for: .todo)
            )
          }

          if !diffItems.isEmpty {
            WorkspaceSessionInspectorDiffSection(
              items: diffItems,
              isExpanded: sectionExpansionBinding(for: .diff)
            )
          }
        }
        .formStyle(.grouped)
      } else {
        ContentUnavailableView(
          "No Session Selected",
          systemImage: "sidebar.right",
          description: Text("Select a session to view context and runtime details.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }

  private func sectionExpansionBinding(for section: WorkspaceSessionInspectorSectionID) -> Binding<Bool> {
    Binding(
      get: { expandedSections.contains(section) },
      set: { isExpanded in
        if isExpanded {
          expandedSections.insert(section)
        } else {
          expandedSections.remove(section)
        }
      }
    )
  }
}

#if os(macOS)
  #Preview("Inspector") {
    WorkspaceSessionInspector(
      bootstrapState: .ready,
      selectedSessionID: "ses_preview_primary"
    )
    .withMacWorkspacePreviewEnv()
    .frame(width: 340, height: 760)
  }

  #Preview("Inspector Loading") {
    WorkspaceSessionInspector(
      bootstrapState: .loading,
      selectedSessionID: nil
    )
    .frame(width: 340, height: 320)
  }

  #Preview("Inspector Failed") {
    WorkspaceSessionInspector(
      bootstrapState: .failed("Lost connection to OpenCode server"),
      selectedSessionID: nil
    )
    .frame(width: 340, height: 320)
  }

  #Preview("Inspector No Session") {
    WorkspaceSessionInspector(
      bootstrapState: .ready,
      selectedSessionID: nil
    )
    .frame(width: 340, height: 320)
    .withMacWorkspacePreviewEnv()
  }
#endif
