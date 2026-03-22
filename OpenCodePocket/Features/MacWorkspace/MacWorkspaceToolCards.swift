#if os(macOS)
  import AppKit
  import OpenCodeSDK
  import SwiftUI
  import TranscriptUI

  private struct MacToolErrorCard: View {
    let errorText: String

    private var parsed: MacToolErrorDetails {
      macParseToolError(errorText)
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        Text(parsed.title)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.red)

        Text(parsed.message)
          .font(.caption)
          .foregroundStyle(.red)

        ForEach(parsed.details, id: \.self) { detail in
          Text(detail)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .padding(8)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color.red.opacity(0.08))
      )
    }
  }

  private struct MacToolErrorDetails {
    let title: String
    let message: String
    let details: [String]
  }

  private func macParseToolError(_ raw: String) -> MacToolErrorDetails {
    let fallback = MacToolErrorDetails(title: "Tool Error", message: raw, details: [])
    guard
      let data = raw.data(using: .utf8),
      let value = try? JSONDecoder().decode(JSONValue.self, from: data),
      let object = value.objectValue
    else {
      return fallback
    }

    let title = object["title"]?.stringValue ?? object["type"]?.stringValue?.capitalized ?? "Tool Error"
    let message = object["message"]?.stringValue ?? object["error"]?.stringValue ?? raw

    var details: [String] = []
    if let code = object["code"]?.stringValue, !code.isEmpty {
      details.append("Code: \(code)")
    }
    if let path = object["path"]?.stringValue, !path.isEmpty {
      details.append("Path: \(path)")
    }
    if let hint = object["hint"]?.stringValue, !hint.isEmpty {
      details.append("Hint: \(hint)")
    }

    if let errors = object["errors"]?.arrayValue {
      for item in errors.prefix(2) {
        if let text = item.stringValue, !text.isEmpty {
          details.append(text)
        } else if let nested = item.objectValue?["message"]?.stringValue, !nested.isEmpty {
          details.append(nested)
        }
      }
    }

    return MacToolErrorDetails(title: title, message: message, details: details)
  }

  struct MacContextToolGroupCard: View {
    let parts: [MessagePart]
    let busy: Bool
    @State private var isExpanded = false

    private var summary: String {
      let reads = parts.filter { $0.tool == "read" }.count
      let searches = parts.filter { $0.tool == "glob" || $0.tool == "grep" }.count
      let lists = parts.filter { $0.tool == "list" }.count

      let chunks = [
        reads > 0 ? "\(reads) read\(reads == 1 ? "" : "s")" : nil,
        searches > 0 ? "\(searches) search\(searches == 1 ? "" : "es")" : nil,
        lists > 0 ? "\(lists) list\(lists == 1 ? "" : "s")" : nil,
      ]
      .compactMap { $0 }

      return chunks.joined(separator: ", ")
    }

    private var hasPendingWork: Bool {
      busy || parts.contains { $0.toolState?.status.isInFlight == true }
    }

    var body: some View {
      DisclosureGroup(isExpanded: $isExpanded) {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(parts) { part in
            let running = part.toolState?.status.isInFlight == true || (busy && part.id == parts.last?.id)
            let args = macContextToolArgs(for: part)
            HStack(spacing: 6) {
              Text(macToolDisplayName(for: part.tool))
                .font(.caption.weight(.semibold))
                .redacted(reason: running ? .placeholder : [])

              if !running, let subtitle = macContextToolSubtitle(for: part), !subtitle.isEmpty {
                Text(subtitle)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }

              if !running, !args.isEmpty {
                Text(args.joined(separator: " "))
                  .font(.caption2)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }

              Spacer(minLength: 0)
            }
          }
        }
        .padding(.top, 6)
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "magnifyingglass")
            .font(.caption)
          Text(hasPendingWork ? "Gathering context..." : "Gathered context")
            .font(.caption.weight(.semibold))
          if !summary.isEmpty {
            Text(summary)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer(minLength: 0)
        }
      }
      .padding(8)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color.secondary.opacity(0.08))
      )
    }
  }

  struct MacToolPartCard: View {
    let part: MessagePart
    let expandShellToolParts: Bool
    let expandEditToolParts: Bool
    @State private var showOutput = false

    init(part: MessagePart, expandShellToolParts: Bool, expandEditToolParts: Bool) {
      self.part = part
      self.expandShellToolParts = expandShellToolParts
      self.expandEditToolParts = expandEditToolParts

      let openOutputByDefault =
        (part.tool == "bash" && expandShellToolParts)
          || ((part.tool == "edit" || part.tool == "write" || part.tool == "apply_patch") && expandEditToolParts)
      _showOutput = State(initialValue: openOutputByDefault)
    }

    private var statusText: String {
      guard let status = part.toolState?.status else {
        return "Pending"
      }

      switch status {
      case .pending, .running:
        return "Running"
      case .completed:
        return "Done"
      case .error:
        return "Error"
      case let .unknown(value):
        return value.capitalized
      }
    }

    private var statusColor: Color {
      guard let status = part.toolState?.status else {
        return .secondary
      }

      switch status {
      case .pending, .running:
        return .orange
      case .completed:
        return .green
      case .error:
        return .red
      case .unknown:
        return .secondary
      }
    }

    @ViewBuilder
    private var detailContent: some View {
      switch part.tool {
      case "bash":
        MacToolBashDetail(part: part, expandedByDefault: expandShellToolParts)
      case "edit":
        MacToolEditPreview(part: part, expandedByDefault: expandEditToolParts)
      case "write":
        MacToolWritePreview(part: part, expandedByDefault: expandEditToolParts)
      case "apply_patch":
        MacToolPatchPreview(part: part, expandedByDefault: expandEditToolParts)
      default:
        EmptyView()
      }
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 8) {
          Image(systemName: macIconName(for: part.tool))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

          Text(macToolDisplayName(for: part.tool))
            .font(.caption.weight(.semibold))

          Spacer(minLength: 0)

          Text(statusText)
            .font(.caption2)
            .foregroundStyle(statusColor)
        }

        if let subtitle = macToolSubtitle(for: part), !subtitle.isEmpty {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        if let error = part.toolState?.error, !error.isEmpty {
          MacToolErrorCard(errorText: error)
        }

        detailContent

        if
          part.tool != "bash",
          let output = part.toolState?.output?.trimmingCharacters(in: .whitespacesAndNewlines),
          !output.isEmpty
        {
          DisclosureGroup("Output", isExpanded: $showOutput) {
            TranscriptMarkdownView(text: output)
              .font(.caption)
              .padding(.top, 4)
          }
        }
      }
      .padding(8)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color.secondary.opacity(0.08))
      )
    }
  }

  private struct MacToolEditPreview: View {
    let part: MessagePart
    @State private var isExpanded: Bool

    init(part: MessagePart, expandedByDefault: Bool) {
      self.part = part
      _isExpanded = State(initialValue: expandedByDefault)
    }

    private var filePath: String? {
      part.toolInputString("filePath")
    }

    private var beforeText: String? {
      let value = part.toolInputString("oldString")?.trimmingCharacters(in: .whitespacesAndNewlines)
      return value?.isEmpty == true ? nil : value
    }

    private var afterText: String? {
      let value = part.toolInputString("newString")?.trimmingCharacters(in: .whitespacesAndNewlines)
      return value?.isEmpty == true ? nil : value
    }

    var body: some View {
      if beforeText != nil || afterText != nil {
        DisclosureGroup("Edit Preview", isExpanded: $isExpanded) {
          VStack(alignment: .leading, spacing: 8) {
            if let filePath {
              Text(filePath)
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            if let beforeText {
              MacToolSnippetBlock(title: "Before", text: beforeText)
            }

            if let afterText {
              MacToolSnippetBlock(title: "After", text: afterText)
            }
          }
          .padding(.top, 6)
        }
        .font(.caption)
      }
    }
  }

  private struct MacToolWritePreview: View {
    let part: MessagePart
    @State private var isExpanded: Bool

    init(part: MessagePart, expandedByDefault: Bool) {
      self.part = part
      _isExpanded = State(initialValue: expandedByDefault)
    }

    private var filePath: String? {
      part.toolInputString("filePath")
    }

    private var content: String? {
      let value = part.toolInputString("content")?.trimmingCharacters(in: .whitespacesAndNewlines)
      return value?.isEmpty == true ? nil : value
    }

    var body: some View {
      if let content {
        DisclosureGroup("Written Content", isExpanded: $isExpanded) {
          VStack(alignment: .leading, spacing: 8) {
            if let filePath {
              Text(filePath)
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            MacToolSnippetBlock(title: "Content", text: content)
          }
          .padding(.top, 6)
        }
        .font(.caption)
      }
    }
  }

  private struct MacToolPatchPreview: View {
    let part: MessagePart
    @State private var isExpanded: Bool

    init(part: MessagePart, expandedByDefault: Bool) {
      self.part = part
      _isExpanded = State(initialValue: expandedByDefault)
    }

    private var files: [String] {
      let fromInput = part.toolState?.input["files"]?.arrayValue?.compactMap { $0.stringValue } ?? []
      if !fromInput.isEmpty {
        return fromInput
      }
      return part.files
    }

    private var patchText: String? {
      let value = part.toolInputString("patchText")?.trimmingCharacters(in: .whitespacesAndNewlines)
      return value?.isEmpty == true ? nil : value
    }

    var body: some View {
      if !files.isEmpty || patchText != nil {
        VStack(alignment: .leading, spacing: 6) {
          if !files.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
              Text("Files")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
              ForEach(files, id: \.self) { file in
                Text(file)
                  .font(.caption2)
                  .lineLimit(2)
              }
            }
          }

          if let patchText {
            DisclosureGroup("Patch Text", isExpanded: $isExpanded) {
              MacToolSnippetBlock(title: "Patch", text: patchText)
                .padding(.top, 6)
            }
            .font(.caption)
          }
        }
      }
    }
  }

  private struct MacToolBashDetail: View {
    let part: MessagePart
    @State private var isExpanded: Bool
    @State private var copied = false

    init(part: MessagePart, expandedByDefault: Bool) {
      self.part = part
      _isExpanded = State(initialValue: expandedByDefault)
    }

    private var text: String {
      let command = part.toolInputString("command") ?? ""
      let output = part.toolState?.output ?? ""
      if command.isEmpty {
        return output
      }
      if output.isEmpty {
        return "$ \(command)"
      }
      return "$ \(command)\n\n\(output)"
    }

    var body: some View {
      if !text.isEmpty {
        DisclosureGroup("Shell Output", isExpanded: $isExpanded) {
          VStack(alignment: .leading, spacing: 6) {
            HStack {
              Spacer(minLength: 0)
              Button {
                macCopyToClipboard(text)
                copied = true
                Task { @MainActor in
                  try? await Task.sleep(nanoseconds: 1_500_000_000)
                  copied = false
                }
              } label: {
                Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                  .font(.caption2)
              }
              .buttonStyle(.plain)
            }

            TranscriptMarkdownView(text: text)
              .font(.caption)
              .padding(8)
              .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                  .fill(Color.secondary.opacity(0.07))
              )
          }
          .padding(.top, 6)
        }
        .font(.caption)
      }
    }
  }

  private struct MacToolSnippetBlock: View {
    let title: String
    let text: String

    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)

        ScrollView(.horizontal) {
          Text(text)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.secondary.opacity(0.07))
        )
      }
    }
  }

  func macToolDisplayName(for tool: String?) -> String {
    switch tool {
    case "read":
      return "Read"
    case "list":
      return "List"
    case "glob":
      return "Glob"
    case "grep":
      return "Grep"
    case "bash":
      return "Shell"
    case "edit":
      return "Edit"
    case "write":
      return "Write"
    case "apply_patch":
      return "Patch"
    case "webfetch":
      return "Web"
    case "question":
      return "Question"
    case "task":
      return "Agent"
    case let value:
      return value ?? "Tool"
    }
  }

  private func macIconName(for tool: String?) -> String {
    switch tool {
    case "bash":
      return "terminal"
    case "read", "glob", "grep", "list":
      return "magnifyingglass"
    case "webfetch":
      return "globe"
    case "write", "edit", "apply_patch":
      return "doc.text"
    case "task":
      return "person.2"
    case "question":
      return "questionmark.bubble"
    default:
      return "hammer"
    }
  }

  private func macToolSubtitle(for part: MessagePart) -> String? {
    switch part.tool {
    case "read":
      return macDisplayPathComponent(part.toolInputString("filePath"))
    case "list":
      return macDisplayPathComponent(part.toolInputString("path"))
    case "glob":
      return part.toolInputString("pattern")
    case "grep":
      return part.toolInputString("pattern")
    case "webfetch":
      return part.toolInputString("url")
    case "bash":
      return part.toolInputString("description")
    case "edit", "write":
      return macDisplayPathComponent(part.toolInputString("filePath"))
    case "apply_patch":
      let fileCount = part.toolState?.input["files"]?.arrayValue?.count ?? 0
      if fileCount > 0 {
        return "\(fileCount) file\(fileCount == 1 ? "" : "s")"
      }
      return nil
    case "task":
      return part.toolInputString("description")
    default:
      if let title = part.toolState?.title, !title.isEmpty {
        return title
      }
      if let error = part.toolState?.error, !error.isEmpty {
        return macParseToolError(error).message
      }
      return nil
    }
  }

  private func macContextToolSubtitle(for part: MessagePart) -> String? {
    switch part.tool {
    case "read":
      return macDisplayPathComponent(part.toolInputString("filePath"))
    case "list", "glob", "grep":
      return part.toolInputString("path")
    default:
      return macToolSubtitle(for: part)
    }
  }

  private func macContextToolArgs(for part: MessagePart) -> [String] {
    switch part.tool {
    case "read":
      var args: [String] = []
      if let offset = macFormattedToolNumber(part.toolInputNumber("offset")) {
        args.append("offset=\(offset)")
      }
      if let limit = macFormattedToolNumber(part.toolInputNumber("limit")) {
        args.append("limit=\(limit)")
      }
      return args
    case "glob":
      if let pattern = part.toolInputString("pattern"), !pattern.isEmpty {
        return ["pattern=\(pattern)"]
      }
      return []
    case "grep":
      var args: [String] = []
      if let pattern = part.toolInputString("pattern"), !pattern.isEmpty {
        args.append("pattern=\(pattern)")
      }
      if let include = part.toolInputString("include"), !include.isEmpty {
        args.append("include=\(include)")
      }
      return args
    default:
      return []
    }
  }

  private func macFormattedToolNumber(_ number: Double?) -> String? {
    guard let number else {
      return nil
    }

    let rounded = number.rounded()
    if abs(number - rounded) < 0.000_001 {
      return String(Int(rounded))
    }
    return String(number)
  }

  private func macDisplayPathComponent(_ rawPath: String?) -> String? {
    guard let rawPath else {
      return nil
    }

    let trimmed = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return nil
    }

    let component = trimmed
      .split(whereSeparator: { $0 == "/" || $0 == "\\" })
      .last
      .map(String.init)
    return component?.isEmpty == false ? component : trimmed
  }

  private func macCopyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
  }
#endif
