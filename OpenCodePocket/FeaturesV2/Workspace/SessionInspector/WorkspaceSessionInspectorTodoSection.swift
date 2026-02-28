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
      isExpanded: .constant(true)
    )
  }
  .formStyle(.grouped)
  .frame(width: 340, height: 280)
}
