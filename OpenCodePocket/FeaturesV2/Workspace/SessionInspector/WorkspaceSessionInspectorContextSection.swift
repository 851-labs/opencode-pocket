import OpenCodeSDK
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
      LabeledContent {
        Text(formattedTokenCount(metrics.tokenCount))
      } label: {
        Label("Tokens", systemImage: "number")
      }

      LabeledContent {
        Text("\(metrics.percentageUsed ?? 0)%")
      } label: {
        Label("Used", systemImage: "percent")
      }

      LabeledContent {
        Text(formattedCost(metrics.cost))
      } label: {
        Label("Spent", systemImage: "dollarsign")
      }
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
  @Previewable @State var isExpanded = true

  Form {
    WorkspaceSessionInspectorContextSection(
      metrics: SessionInspectorContextMetrics(
        tokenCount: 54096,
        percentageUsed: 14,
        cost: 0
      ),
      isExpanded: $isExpanded
    )
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 220)
}
