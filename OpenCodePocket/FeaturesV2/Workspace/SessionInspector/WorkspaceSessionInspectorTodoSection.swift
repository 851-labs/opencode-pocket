import OpenCodeModels
import SwiftUI

struct WorkspaceSessionInspectorTodoSection: View {
  let items: [TodoItem]
  @Binding var isExpanded: Bool

  var body: some View {
    WorkspaceSessionInspectorCollapsibleSection(
      title: "Todo",
      collapsedSummary: nil,
      accessibilityID: "workspace.inspector.todo",
      isExpanded: $isExpanded
    ) {
      ForEach(items) { todo in
        Label {
          Text(todo.content)
            .foregroundStyle(todo.status == "completed" || todo.status == "cancelled" ? .secondary : .primary)
            .strikethrough(todo.status == "completed" || todo.status == "cancelled")
            .lineLimit(2)
        } icon: {
          todoIcon(todo.status)
        }
      }
    }
  }

  private func todoIcon(_ status: String) -> some View {
    Image(systemName: status == "in_progress" ? "circle.righthalf.filled" : todoIconName(status))
      .foregroundStyle(status == "in_progress" ? .yellow : todoIconColor(status))
  }

  private func todoIconName(_ status: String) -> String {
    switch status {
    case "completed":
      return "checkmark.circle.fill"
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
    case "cancelled":
      return .secondary
    default:
      return .secondary
    }
  }
}

#Preview("Todo Section") {
  @Previewable @State var isExpanded = true

  Form {
    WorkspaceSessionInspectorTodoSection(
      items: [
        TodoItem(content: "Ship inspector refactor", status: "in_progress", priority: "high"),
        TodoItem(content: "Write changelog note", status: "pending", priority: "medium"),
        TodoItem(content: "Archive stale branch", status: "completed", priority: "low"),
      ],
      isExpanded: $isExpanded
    )
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 280)
}
