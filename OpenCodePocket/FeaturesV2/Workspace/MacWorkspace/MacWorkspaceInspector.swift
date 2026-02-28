#if os(macOS)
  import OpenCodeModels
  import SwiftUI

  private enum MacWorkspaceInspectorSection: Hashable {
    case mcp
    case lsp
    case todo
    case diff
  }

  struct MacWorkspaceInspector: View {
    @Environment(WorkspaceStore.self) private var store

    let bootstrapState: MacWorkspaceBootstrapState
    let selectedSessionID: String?

    @State private var expandedSections: Set<MacWorkspaceInspectorSection> = [.mcp, .lsp, .todo, .diff]

    private var contextMetrics: SessionInspectorContextMetrics {
      guard let selectedSessionID else {
        return SessionInspectorContextMetrics(tokenCount: 0, percentageUsed: nil, cost: 0)
      }
      return store.inspectorContextMetrics(for: selectedSessionID)
    }

    private var mcpEntries: [(name: String, status: MCPServerStatus)] {
      store.mcpStatuses.keys.sorted().compactMap { name in
        guard let status = store.mcpStatuses[name] else {
          return nil
        }
        return (name: name, status: status)
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
            contextSection

            if !mcpEntries.isEmpty {
              mcpSection
            }

            lspSection

            if shouldShowTodoSection {
              todoSection
            }

            if !diffItems.isEmpty {
              diffSection
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

    private var contextSection: some View {
      Section {
        Text("\(formattedTokenCount(contextMetrics.tokenCount)) tokens")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("\(contextMetrics.percentageUsed ?? 0)% used")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("\(formattedCost(contextMetrics.cost)) spent")
          .font(.caption)
          .foregroundStyle(.secondary)
      } header: {
        Text("Context")
          .textCase(nil)
      }
      .accessibilityIdentifier("workspace.inspector.context")
    }

    private var mcpSection: some View {
      section(
        "MCP",
        id: .mcp,
        rowCount: mcpEntries.count,
        collapsedSummary: mcpCollapsedSummary,
        accessibilityID: "workspace.inspector.mcp"
      ) {
        ForEach(mcpEntries, id: \.name) { item in
          HStack(alignment: .top, spacing: 8) {
            Circle()
              .fill(mcpColor(for: item.status.status))
              .frame(width: 7, height: 7)
              .padding(.top, 4)

            Text(item.name)
              .font(.caption)

            Spacer(minLength: 6)

            Text(mcpStatusText(for: item.status))
              .font(.caption)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.trailing)
          }
        }
      }
    }

    private var lspSection: some View {
      section(
        "LSP",
        id: .lsp,
        rowCount: lspEntries.count,
        accessibilityID: "workspace.inspector.lsp"
      ) {
        if lspEntries.isEmpty {
          Text("LSPs will activate as files are read")
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
          ForEach(lspEntries) { item in
            HStack(alignment: .top, spacing: 8) {
              Circle()
                .fill(lspColor(for: item.status))
                .frame(width: 7, height: 7)
                .padding(.top, 4)

              Text("\(item.id) \(item.root)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }
          }
        }
      }
    }

    private var todoSection: some View {
      section(
        "Todo",
        id: .todo,
        rowCount: todoItems.count,
        accessibilityID: "workspace.inspector.todo"
      ) {
        ForEach(todoItems) { todo in
          HStack(alignment: .top, spacing: 8) {
            Image(systemName: todoIconName(todo.status))
              .font(.caption)
              .foregroundStyle(todoIconColor(todo.status))
              .padding(.top, 2)

            Text(todo.content)
              .font(.caption)
              .foregroundStyle(todo.status == "completed" || todo.status == "cancelled" ? .secondary : .primary)
              .strikethrough(todo.status == "completed" || todo.status == "cancelled")
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }

    private var diffSection: some View {
      section(
        "Modified Files",
        id: .diff,
        rowCount: diffItems.count,
        accessibilityID: "workspace.inspector.diff"
      ) {
        ForEach(diffItems) { diff in
          HStack(alignment: .top, spacing: 8) {
            Text(diff.file)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)

            Spacer(minLength: 6)

            HStack(spacing: 6) {
              if diff.additionsCount > 0 {
                Text("+\(diff.additionsCount)")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.green)
              }

              if diff.deletionsCount > 0 {
                Text("-\(diff.deletionsCount)")
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.red)
              }
            }
          }
        }
      }
    }

    private func section<Content: View>(
      _ title: String,
      id: MacWorkspaceInspectorSection,
      rowCount: Int,
      collapsedSummary: String? = nil,
      accessibilityID: String,
      @ViewBuilder content: () -> Content
    ) -> some View {
      let collapsible = rowCount > 2
      let expanded = collapsible ? expandedSections.contains(id) : true

      return Section {
        if expanded {
          content()
        }
      } header: {
        Button {
          guard collapsible else {
            return
          }

          if expanded {
            expandedSections.remove(id)
          } else {
            expandedSections.insert(id)
          }
        } label: {
          HStack(spacing: 6) {
            if collapsible {
              Image(systemName: expanded ? "chevron.down" : "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            }

            Text(title)
              .font(.caption.weight(.semibold))
              .textCase(nil)

            if collapsible, !expanded, let collapsedSummary, !collapsedSummary.isEmpty {
              Text("(\(collapsedSummary))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .textCase(nil)
            }

            Spacer(minLength: 0)
          }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("\(accessibilityID).toggle")
      }
      .accessibilityIdentifier(accessibilityID)
    }

    private func formattedTokenCount(_ value: Int) -> String {
      value.formatted(.number.grouping(.automatic))
    }

    private func formattedCost(_ value: Double) -> String {
      value.formatted(.currency(code: "USD"))
    }

    private func lspColor(for status: LSPServerConnectionState) -> Color {
      switch status {
      case .connected:
        return .green
      case .error:
        return .red
      case .unknown:
        return .secondary
      }
    }

    private func mcpColor(for status: MCPServerConnectionState) -> Color {
      switch status {
      case .connected:
        return .green
      case .failed, .needsClientRegistration:
        return .red
      case .needsAuth:
        return .orange
      case .disabled, .unknown:
        return .secondary
      }
    }

    private func mcpStatusText(for status: MCPServerStatus) -> String {
      switch status.status {
      case .connected:
        return "Connected"
      case .disabled:
        return "Disabled"
      case .failed:
        return status.error?.trimmedNonEmpty ?? "Failed"
      case .needsAuth:
        return "Needs auth"
      case .needsClientRegistration:
        return "Needs client ID"
      case let .unknown(rawValue):
        return rawValue
      }
    }

    private func todoIconName(_ status: String) -> String {
      switch status {
      case "completed":
        return "checkmark.circle.fill"
      case "in_progress":
        return "circle.fill"
      case "cancelled":
        return "xmark.circle"
      default:
        return "circle"
      }
    }

    private func todoIconColor(_ status: String) -> Color {
      switch status {
      case "completed":
        return .green
      case "in_progress":
        return .blue
      case "cancelled":
        return .secondary
      default:
        return .secondary
      }
    }
  }

  #Preview("Inspector") {
    MacWorkspaceInspector(
      bootstrapState: .ready,
      selectedSessionID: "ses_preview_primary"
    )
    .withMacWorkspacePreviewEnv()
    .frame(width: 340, height: 760)
  }
#endif
