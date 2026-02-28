import OpenCodeModels
import SwiftUI

struct WorkspaceSessionInspectorContextSection: View {
  let metrics: SessionInspectorContextMetrics
  @Binding var isExpanded: Bool

  var body: some View {
    WorkspaceSessionInspectorCollapsibleSection(
      title: "Context",
      collapsedSummary: nil,
      accessibilityID: "workspace.inspector.context",
      isExpanded: $isExpanded
    ) {
      Text("\(formattedTokenCount(metrics.tokenCount)) tokens")
        .font(.caption)
        .foregroundStyle(.secondary)

      Text("\(metrics.percentageUsed ?? 0)% used")
        .font(.caption)
        .foregroundStyle(.secondary)

      Text("\(formattedCost(metrics.cost)) spent")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private func formattedTokenCount(_ value: Int) -> String {
    value.formatted(.number.grouping(.automatic))
  }

  private func formattedCost(_ value: Double) -> String {
    value.formatted(.currency(code: "USD"))
  }
}

#Preview("Context Section") {
  Form {
    WorkspaceSessionInspectorContextSection(
      metrics: SessionInspectorContextMetrics(
        tokenCount: 54096,
        percentageUsed: 14,
        cost: 0
      ),
      isExpanded: .constant(true)
    )
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 220)
}
