import OpenCodeModels
import SwiftUI

struct WorkspaceSessionInspectorContextSection: View {
  let metrics: SessionInspectorContextMetrics

  var body: some View {
    Section {
      Text("\(formattedTokenCount(metrics.tokenCount)) tokens")
        .font(.caption)
        .foregroundStyle(.secondary)

      Text("\(metrics.percentageUsed ?? 0)% used")
        .font(.caption)
        .foregroundStyle(.secondary)

      Text("\(formattedCost(metrics.cost)) spent")
        .font(.caption)
        .foregroundStyle(.secondary)
    } header: {
      Text("Context")
        .textCase(nil)
    }
    .accessibilityIdentifier("workspace.inspector.context")
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
      )
    )
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 220)
}
