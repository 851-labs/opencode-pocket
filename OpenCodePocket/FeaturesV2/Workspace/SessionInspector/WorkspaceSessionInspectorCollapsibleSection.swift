import SwiftUI

struct WorkspaceSessionInspectorCollapsibleSection<Content: View>: View {
  let title: String
  let rowCount: Int
  let collapsedSummary: String?
  let accessibilityID: String
  let isExpanded: Bool
  let onToggle: () -> Void
  @ViewBuilder let content: () -> Content

  private var isCollapsible: Bool {
    rowCount > 2
  }

  private var expanded: Bool {
    isCollapsible ? isExpanded : true
  }

  var body: some View {
    Section {
      if expanded {
        content()
      }
    } header: {
      Button {
        guard isCollapsible else {
          return
        }
        onToggle()
      } label: {
        HStack(spacing: 6) {
          if isCollapsible {
            Image(systemName: expanded ? "chevron.down" : "chevron.right")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(.secondary)
          }

          Text(title)
            .font(.caption.weight(.semibold))
            .textCase(nil)

          if isCollapsible, !expanded, let collapsedSummary, !collapsedSummary.isEmpty {
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
}

#Preview("Collapsible Section Expanded") {
  Form {
    WorkspaceSessionInspectorCollapsibleSection(
      title: "Sample",
      rowCount: 3,
      collapsedSummary: "2 active",
      accessibilityID: "workspace.inspector.sample",
      isExpanded: true,
      onToggle: {}
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
  Form {
    WorkspaceSessionInspectorCollapsibleSection(
      title: "Sample",
      rowCount: 3,
      collapsedSummary: "2 active",
      accessibilityID: "workspace.inspector.sample",
      isExpanded: false,
      onToggle: {}
    ) {
      Text("First row")
      Text("Second row")
      Text("Third row")
    }
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 220)
}
