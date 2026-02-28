#if os(macOS)
  import OpenCodeModels
  import SwiftUI

  struct MacTodoDockCard: View {
    let todos: [TodoItem]
    @State private var isCollapsed = false

    private var completedCount: Int {
      todos.filter { $0.status == "completed" }.count
    }

    private var allDone: Bool {
      !todos.isEmpty && todos.allSatisfy { $0.status == "completed" || $0.status == "cancelled" }
    }

    private var summary: String {
      "\(completedCount) of \(todos.count) tasks completed"
    }

    private var preview: String {
      todos.first(where: { $0.status == "in_progress" })?.content
        ?? todos.first(where: { $0.status == "pending" })?.content
        ?? todos.last?.content
        ?? ""
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          Text(summary)
            .font(.caption)
            .foregroundStyle(.secondary)

          if isCollapsed && !preview.isEmpty {
            Text(preview)
              .font(.caption)
              .lineLimit(1)
              .foregroundStyle(.secondary)
          }

          Spacer(minLength: 0)

          Button {
            withAnimation(.easeInOut(duration: 0.2)) {
              isCollapsed.toggle()
            }
          } label: {
            Image(systemName: "chevron.down")
              .font(.caption.weight(.semibold))
              .rotationEffect(.degrees(isCollapsed ? 0 : 180))
          }
          .buttonStyle(.plain)
        }

        if !isCollapsed {
          VStack(alignment: .leading, spacing: 6) {
            ForEach(todos) { todo in
              HStack(alignment: .top, spacing: 8) {
                Image(systemName: todoIconName(todo.status))
                  .font(.caption)
                  .foregroundStyle(todoIconColor(todo.status))

                Text(todo.content)
                  .font(.caption)
                  .foregroundStyle(todo.status == "completed" || todo.status == "cancelled" ? .secondary : .primary)
                  .strikethrough(todo.status == "completed" || todo.status == "cancelled")
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }
        }
      }
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(Color.secondary.opacity(0.08))
      )
      .onChange(of: allDone) { _, done in
        if done {
          withAnimation(.easeInOut(duration: 0.25)) {
            isCollapsed = true
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

  struct MacPermissionPromptCard: View {
    @Environment(WorkspaceStore.self) private var store
    let sessionID: String
    let request: PermissionRequest

    private var hint: String? {
      macPermissionHint(for: request.permission)
    }

    private var linkedToolPart: MessagePart? {
      store.linkedToolPart(for: sessionID, reference: request.tool)
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        Label("Permission Needed", systemImage: "exclamationmark.triangle")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.orange)

        Text(request.permission)
          .font(.subheadline.weight(.semibold))

        if let hint {
          Text(hint)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        if !request.patterns.isEmpty {
          VStack(alignment: .leading, spacing: 4) {
            ForEach(request.patterns, id: \.self) { pattern in
              Text(pattern)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                  RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
                )
            }
          }
        }

        if let linkedToolPart {
          MacPromptToolLinkRow(part: linkedToolPart)
        }

        HStack(spacing: 8) {
          Button("Deny", role: .destructive) {
            Task {
              await store.respondToPermission(sessionID: sessionID, requestID: request.id, reply: .reject)
            }
          }
          .disabled(store.isRespondingToPermission(requestID: request.id))

          Button("Allow Always") {
            Task {
              await store.respondToPermission(sessionID: sessionID, requestID: request.id, reply: .always)
            }
          }
          .disabled(store.isRespondingToPermission(requestID: request.id))

          Button("Allow Once") {
            Task {
              await store.respondToPermission(sessionID: sessionID, requestID: request.id, reply: .once)
            }
          }
          .buttonStyle(.borderedProminent)
          .disabled(store.isRespondingToPermission(requestID: request.id))
        }
        .font(.caption)
      }
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(Color.orange.opacity(0.08))
      )
    }
  }

  private struct MacPromptToolLinkRow: View {
    let part: MessagePart

    private var label: String {
      let tool = macToolDisplayName(for: part.tool)
      let call = part.callID ?? "unknown"
      return "Linked tool: \(tool) (\(call))"
    }

    var body: some View {
      HStack(spacing: 6) {
        Image(systemName: "link")
          .font(.caption2)
          .foregroundStyle(.secondary)

        Text(label)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color.secondary.opacity(0.08))
      )
    }
  }

  private func macPermissionHint(for permission: String) -> String? {
    switch permission {
    case "read":
      return "Allow the assistant to read files from your workspace."
    case "write":
      return "Allow the assistant to create new files in your workspace."
    case "edit":
      return "Allow the assistant to modify existing files."
    case "bash":
      return "Allow the assistant to run shell commands."
    case "webfetch":
      return "Allow the assistant to fetch content from external URLs."
    case "task":
      return "Allow the assistant to launch sub-agents for delegated tasks."
    default:
      return nil
    }
  }

  struct MacQuestionPromptCard: View {
    @Environment(WorkspaceStore.self) private var store
    let sessionID: String
    let request: QuestionRequest

    @State private var tab = 0
    @State private var answers: [QuestionAnswer] = []
    @State private var customAnswers: [String] = []
    @State private var isEditingCustom = false

    private var total: Int {
      request.questions.count
    }

    private var question: QuestionDefinition? {
      guard request.questions.indices.contains(tab) else {
        return nil
      }
      return request.questions[tab]
    }

    private var options: [QuestionOption] {
      question?.options ?? []
    }

    private var isMultiple: Bool {
      question?.multiple == true
    }

    private var isSending: Bool {
      store.isRespondingToQuestion(requestID: request.id)
    }

    private var isLastQuestion: Bool {
      tab >= total - 1
    }

    private var summary: String {
      guard total > 0 else {
        return "0 of 0 questions"
      }
      let current = min(tab + 1, total)
      return "\(current) of \(total) questions"
    }

    private var customInput: String {
      customAnswers[safe: tab] ?? ""
    }

    private var selectedAnswers: [String] {
      answers[safe: tab] ?? []
    }

    private var linkedToolPart: MessagePart? {
      store.linkedToolPart(for: sessionID, reference: request.tool)
    }

    private var parsedAnswers: [QuestionAnswer] {
      request.questions.enumerated().map { index, _ in
        let raw = answers[safe: index] ?? []
        var unique: [String] = []
        for value in raw.map(\.trimmedForInput).filter({ !$0.isEmpty }) where !unique.contains(value) {
          unique.append(value)
        }
        return unique
      }
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .center, spacing: 10) {
          Text(summary)
            .font(.caption.weight(.semibold))

          Spacer(minLength: 0)

          HStack(spacing: 6) {
            ForEach(Array(request.questions.enumerated()), id: \.offset) { index, _ in
              let answered = (answers[safe: index]?.isEmpty == false)
              let active = index == tab
              Button {
                guard !isSending else { return }
                tab = index
                isEditingCustom = false
              } label: {
                Capsule(style: .continuous)
                  .fill(active ? Color.primary : (answered ? Color.accentColor : Color.secondary.opacity(0.35)))
                  .frame(width: 16, height: 3)
              }
              .buttonStyle(.plain)
              .accessibilityIdentifier("question.progress.\(index)")
            }
          }
        }

        if let question {
          if let linkedToolPart {
            MacPromptToolLinkRow(part: linkedToolPart)
          }

          Text(question.question)
            .font(.caption.weight(.semibold))

          Text(isMultiple ? "Choose one or more options." : "Choose one option.")
            .font(.caption)
            .foregroundStyle(.secondary)

          VStack(alignment: .leading, spacing: 6) {
            ForEach(options, id: \.label) { option in
              let isSelected = selectedAnswers.contains(option.label)

              Button {
                guard !isSending else { return }
                selectOption(option.label)
              } label: {
                HStack(alignment: .top, spacing: 10) {
                  Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                  VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                      .font(.caption.weight(.semibold))
                      .lineLimit(1)

                    if !option.description.isEmpty {
                      Text(option.description)
                        .font(.caption2)
                        .lineLimit(2)
                    }
                  }

                  Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(
                  RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                )
              }
              .buttonStyle(.plain)
              .disabled(isSending)
            }

            if isEditingCustom {
              HStack(spacing: 8) {
                TextField("Type your answer", text: customBinding)
                  .textFieldStyle(.roundedBorder)
                  .disabled(isSending)

                Button("Add") {
                  commitCustomAnswer()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSending)

                Button("Cancel") {
                  isEditingCustom = false
                }
                .disabled(isSending)
              }
            } else {
              let picked = selectedAnswers.contains(customInput.trimmedForInput) && !customInput.trimmedForInput.isEmpty
              Button {
                guard !isSending else { return }
                isEditingCustom = true
              } label: {
                HStack(spacing: 10) {
                  Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundStyle(picked ? Color.accentColor : Color.secondary)

                  VStack(alignment: .leading, spacing: 2) {
                    Text("Type your own answer")
                      .font(.caption.weight(.semibold))
                    if !customInput.trimmedForInput.isEmpty {
                      Text(customInput)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    }
                  }

                  Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(
                  RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
                )
              }
              .buttonStyle(.plain)
              .disabled(isSending)
            }
          }
        }

        HStack(spacing: 8) {
          Button("Dismiss", role: .destructive) {
            Task {
              await store.rejectQuestion(sessionID: sessionID, requestID: request.id)
            }
          }
          .disabled(isSending)

          if tab > 0 {
            Button("Back") {
              guard !isSending else { return }
              tab -= 1
              isEditingCustom = false
            }
            .disabled(isSending)
          }

          Spacer()

          Button(isLastQuestion ? "Submit" : "Next") {
            if isEditingCustom {
              commitCustomAnswer()
            }

            if !isLastQuestion {
              tab += 1
              isEditingCustom = false
              return
            }

            Task {
              await store.replyToQuestion(sessionID: sessionID, requestID: request.id, answers: parsedAnswers)
            }
          }
          .buttonStyle(.borderedProminent)
          .disabled(isSending || parsedAnswers.allSatisfy(\.isEmpty))
        }
        .font(.caption)
      }
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(Color.blue.opacity(0.08))
      )
      .onAppear {
        resetState()
      }
      .onChange(of: request.id) { _, _ in
        resetState()
      }
    }

    private var customBinding: Binding<String> {
      Binding(
        get: {
          customAnswers[safe: tab] ?? ""
        },
        set: { value in
          ensureCapacity(for: tab)
          customAnswers[tab] = value
        }
      )
    }

    private func selectOption(_ option: String) {
      ensureCapacity(for: tab)

      if !isMultiple {
        answers[tab] = [option]
        isEditingCustom = false
        return
      }

      var selected = answers[tab]
      if let selectedIndex = selected.firstIndex(of: option) {
        selected.remove(at: selectedIndex)
      } else {
        selected.append(option)
      }

      answers[tab] = selected
    }

    private func commitCustomAnswer() {
      let value = customInput.trimmedForInput
      ensureCapacity(for: tab)
      customAnswers[tab] = value

      guard !value.isEmpty else {
        isEditingCustom = false
        return
      }

      if isMultiple {
        if !answers[tab].contains(value) {
          answers[tab].append(value)
        }
        isEditingCustom = false
        return
      }

      answers[tab] = [value]
      isEditingCustom = false
    }

    private func ensureCapacity(for index: Int) {
      if index < answers.count {
        return
      }

      let growBy = (index - answers.count) + 1
      answers.append(contentsOf: Array(repeating: [], count: growBy))
      customAnswers.append(contentsOf: Array(repeating: "", count: growBy))
    }

    private func resetState() {
      tab = 0
      answers = Array(repeating: [], count: request.questions.count)
      customAnswers = Array(repeating: "", count: request.questions.count)
      isEditingCustom = false
    }
  }
#endif
