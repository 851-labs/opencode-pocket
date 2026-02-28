import OpenCodeModels
import SwiftUI

struct WorkspaceSessionInspectorMCPSection: View {
  let entries: [WorkspaceSessionInspectorMCPEntry]
  let collapsedSummary: String
  @Binding var isExpanded: Bool

  var body: some View {
    WorkspaceSessionInspectorCollapsibleSection(
      title: "MCP",
      collapsedSummary: collapsedSummary,
      accessibilityID: "workspace.inspector.mcp",
      isExpanded: $isExpanded
    ) {
      ForEach(entries) { item in
        LabeledContent {
          Text(mcpStatusText(for: item.status))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
        } label: {
          Label {
            Text(item.name)
          } icon: {
            Circle()
              .fill(mcpColor(for: item.status.status))
              .frame(width: 8, height: 8)
          }
        }
      }
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
}

#Preview("MCP Section") {
  Form {
    WorkspaceSessionInspectorMCPSection(
      entries: [
        WorkspaceSessionInspectorMCPEntry(name: "grafana", status: MCPServerStatus(status: .connected)),
        WorkspaceSessionInspectorMCPEntry(name: "posthog", status: MCPServerStatus(status: .connected)),
        WorkspaceSessionInspectorMCPEntry(name: "replicate", status: MCPServerStatus(status: .failed, error: "Handshake failed")),
      ],
      collapsedSummary: "2 active, 1 error",
      isExpanded: .constant(true)
    )
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 280)
}
