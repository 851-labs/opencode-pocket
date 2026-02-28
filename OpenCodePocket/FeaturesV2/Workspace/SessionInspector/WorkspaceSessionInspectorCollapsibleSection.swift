import SwiftUI

struct WorkspaceSessionInspectorCollapsibleSection<Content: View>: View {
  let title: String
  let collapsedSummary: String?
  let accessibilityID: String
  @Binding var isExpanded: Bool
  @ViewBuilder let content: () -> Content

  var body: some View {
    Section(isExpanded: $isExpanded) {
      content()
    } header: {
      HStack(spacing: 6) {
        Text(title)
          .font(.caption.weight(.semibold))
          .textCase(nil)

        if !isExpanded, let collapsedSummary, !collapsedSummary.isEmpty {
          Text("(\(collapsedSummary))")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .textCase(nil)
        }

        Spacer(minLength: 0)
      }
      .accessibilityIdentifier("\(accessibilityID).toggle")
    }
    .accessibilityIdentifier(accessibilityID)
  }
}

#Preview("Collapsible Section Expanded") {
  @Previewable @State var isExpanded = true

  Form {
    WorkspaceSessionInspectorCollapsibleSection(
      title: "Sample",
      collapsedSummary: "2 active",
      accessibilityID: "workspace.inspector.sample",
      isExpanded: $isExpanded
    ) {
      Text("First row")
      Text("Second row")
      Text("Third row")
    }
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 260)
}

#Preview("Collapsible Section Collapsed") {
  @Previewable @State var isExpanded = false

  Form {
    WorkspaceSessionInspectorCollapsibleSection(
      title: "Sample",
      collapsedSummary: "2 active",
      accessibilityID: "workspace.inspector.sample",
      isExpanded: $isExpanded
    ) {
      Text("First row")
      Text("Second row")
      Text("Third row")
    }
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 220)
}
