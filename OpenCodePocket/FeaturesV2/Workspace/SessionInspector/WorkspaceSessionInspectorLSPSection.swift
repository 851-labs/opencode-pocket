import OpenCodeModels
import SwiftUI

struct WorkspaceSessionInspectorLSPSection: View {
  let entries: [LSPServerStatus]
  @Binding var isExpanded: Bool

  var body: some View {
    WorkspaceSessionInspectorCollapsibleSection(
      title: "LSP",
      collapsedSummary: nil,
      accessibilityID: "workspace.inspector.lsp",
      isExpanded: $isExpanded
    ) {
      if entries.isEmpty {
        Text("LSPs will activate as files are read")
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        ForEach(entries) { item in
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
}

#Preview("LSP Section Empty") {
  Form {
    WorkspaceSessionInspectorLSPSection(
      entries: [],
      isExpanded: .constant(true)
    )
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 220)
}

#Preview("LSP Section Active") {
  Form {
    WorkspaceSessionInspectorLSPSection(
      entries: [
        LSPServerStatus(id: "typescript", name: "TypeScript", root: "apps/emoji", status: .connected),
        LSPServerStatus(id: "ruby", name: "Ruby", root: "apps/api", status: .error),
      ],
      isExpanded: .constant(true)
    )
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 260)
}
