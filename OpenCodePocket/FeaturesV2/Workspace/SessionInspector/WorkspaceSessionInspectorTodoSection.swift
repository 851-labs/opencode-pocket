import OpenCodeModels
import SwiftUI

struct WorkspaceSessionInspectorTodoSection: View {
  let items: [TodoItem]
  let isExpanded: Bool
  let onToggleExpanded: () -> Void

  var body: some View {
    WorkspaceSessionInspectorCollapsibleSection(
      title: "Todo",
      rowCount: items.count,
      collapsedSummary: nil,
      accessibilityID: "workspace.inspector.todo",
      isExpanded: isExpanded,
      onToggle: onToggleExpanded
    ) {
      ForEach(items) { todo in
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

#Preview("Todo Section") {
  Form {
    WorkspaceSessionInspectorTodoSection(
      items: [
        TodoItem(content: "Ship inspector refactor", status: "in_progress", priority: "high"),
        TodoItem(content: "Write changelog note", status: "pending", priority: "medium"),
        TodoItem(content: "Archive stale branch", status: "completed", priority: "low"),
      ],
      isExpanded: true,
      onToggleExpanded: {}
    )
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 280)
}
