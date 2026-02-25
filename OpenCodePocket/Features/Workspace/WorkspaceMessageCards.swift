import OpenCodeModels
import SwiftUI
import TranscriptUI

#if os(iOS)

  struct UserMessageCard: View {
    let message: MessageEnvelope

    @State private var copied = false

    private var attachments: [MessageAttachment] {
      message.parts.compactMap(MessageAttachment.init(part:))
    }

    private var metadata: String {
      userMessageMetadata(for: message)
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        if !attachments.isEmpty {
          AttachmentStrip(attachments: attachments)
        }

        HighlightedUserText(text: message.textBody)
          .font(.body)

        HStack(spacing: 8) {
          if !metadata.isEmpty {
            Text(metadata)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }

          Button {
            copyText(message.textBody)
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
              copied = false
            }
          } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(copied ? "Copied" : "Copy")
          .accessibilityIdentifier("message.user.copy.\(message.id)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Color.accentColor.opacity(0.16))
      )
      .accessibilityElement(children: .contain)
      .accessibilityLabel("User message")
    }
  }

  private struct HighlightedUserText: View {
    let text: String

    private var highlighted: AttributedString {
      highlightedUserText(text)
    }

    var body: some View {
      Text(highlighted)
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private struct AttachmentStrip: View {
    let attachments: [MessageAttachment]

    var body: some View {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 8)], spacing: 8) {
        ForEach(attachments) { attachment in
          if let url = URL(string: attachment.url) {
            Link(destination: url) {
              AttachmentThumb(attachment: attachment)
            }
            .buttonStyle(.plain)
          } else {
            AttachmentThumb(attachment: attachment)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .trailing)
    }
  }

  private struct AttachmentThumb: View {
    let attachment: MessageAttachment

    var body: some View {
      Group {
        if attachment.isImage, let url = URL(string: attachment.url) {
          AsyncImage(url: url) { phase in
            if let image = phase.image {
              image
                .resizable()
                .scaledToFill()
            } else {
              Color.secondary.opacity(0.15)
                .overlay(Image(systemName: "photo").font(.caption))
            }
          }
        } else {
          Color.secondary.opacity(0.15)
            .overlay(
              Image(systemName: attachment.isPDF ? "doc.richtext" : "doc")
                .font(.caption)
                .foregroundStyle(.secondary)
            )
        }
      }
      .frame(width: 48, height: 48)
      .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 6, style: .continuous)
          .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
      )
    }
  }

  private struct MessageAttachment: Identifiable {
    let id: String
    let mime: String
    let name: String
    let url: String

    var isImage: Bool {
      mime.hasPrefix("image/")
    }

    var isPDF: Bool {
      mime == "application/pdf"
    }

    init?(part: MessagePart) {
      guard part.type == "file" else {
        return nil
      }
      guard let url = part.fileURL, !url.isEmpty else {
        return nil
      }
      let mime = part.fileMime ?? "application/octet-stream"
      guard mime.hasPrefix("image/") || mime == "application/pdf" else {
        return nil
      }

      id = part.id
      self.mime = mime
      name = part.fileName ?? "Attachment"
      self.url = url
    }
  }

  func highlightedUserText(_ text: String) -> AttributedString {
    var result = AttributedString(text)
    let nsText = text as NSString
    let fullRange = NSRange(location: 0, length: nsText.length)

    if let fileRegex = try? NSRegularExpression(pattern: #"\[[Ff]ile:[^\]]+\]"#) {
      for match in fileRegex.matches(in: text, range: fullRange) {
        if let range = Range(match.range, in: result) {
          result[range].foregroundColor = .blue
        }
      }
    }

    if let agentRegex = try? NSRegularExpression(pattern: #"@[A-Za-z0-9_\-.]+"#) {
      for match in agentRegex.matches(in: text, range: fullRange) {
        if let range = Range(match.range, in: result) {
          result[range].foregroundColor = .green
        }
      }
    }

    return result
  }

  private func userMessageMetadata(for message: MessageEnvelope) -> String {
    var chunks: [String] = []
    if let agent = message.info.agent?.trimmedForInput, !agent.isEmpty {
      chunks.append(agent.capitalized)
    }
    if let model = message.info.modelID?.trimmedForInput, !model.isEmpty {
      chunks.append(model)
    }
    if let time = formattedClockTime(from: message.info.createdAt) {
      chunks.append(time)
    }
    return chunks.joined(separator: " · ")
  }

  private func formattedClockTime(from raw: Double?) -> String? {
    guard let raw else {
      return nil
    }

    let seconds = raw > 10_000_000_000 ? raw / 1000 : raw
    let date = Date(timeIntervalSince1970: seconds)
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
  }

  private func assistantMessageMetadata(for message: MessageEnvelope, turnDurationMs: Double?) -> String {
    var chunks: [String] = []
    if let model = message.info.modelID?.trimmedForInput, !model.isEmpty {
      chunks.append(model)
    }
    if
      let duration = formattedReplyDuration(
        turnDurationMs: turnDurationMs,
        createdRaw: message.info.createdAt,
        completedRaw: message.info.completedAt
      )
    {
      chunks.append(duration)
    }
    return chunks.joined(separator: " · ")
  }

  private func formattedReplyDuration(turnDurationMs: Double?, createdRaw: Double?, completedRaw: Double?) -> String? {
    let durationMs: Double
    if let turnDurationMs, turnDurationMs >= 0 {
      durationMs = turnDurationMs
    } else {
      guard let createdRaw, let completedRaw else {
        return nil
      }

      let createdMs = epochMilliseconds(from: createdRaw)
      let completedMs = epochMilliseconds(from: completedRaw)
      let fallbackMs = completedMs - createdMs
      guard fallbackMs >= 0 else {
        return nil
      }
      durationMs = fallbackMs
    }

    let totalSeconds = Int((durationMs / 1000).rounded())
    if totalSeconds < 60 {
      return "\(totalSeconds)s"
    }

    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return "\(minutes)m \(seconds)s"
  }

  private func epochMilliseconds(from raw: Double) -> Double {
    raw > 10_000_000_000 ? raw : raw * 1000
  }

  private func assistantCopyText(for message: MessageEnvelope, includeReasoning: Bool) -> String {
    let text = message.parts
      .filter { part in
        part.type == "text" || (includeReasoning && part.type == "reasoning")
      }
      .compactMap(\.text)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n\n")

    if !text.isEmpty {
      return text
    }

    return message.textBody
  }

  func extractReasoningHeading(from text: String) -> String? {
    let lines = text
      .components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    guard let first = lines.first else {
      return nil
    }

    if first.hasPrefix("#") {
      let heading = first.drop { $0 == "#" || $0 == " " }
      return heading.isEmpty ? nil : String(heading)
    }

    return String(first.prefix(80))
  }

  struct AssistantMessageCard: View {
    let message: MessageEnvelope
    let busy: Bool
    let showReasoningSummaries: Bool
    let turnDurationMs: Double?
    let expandShellToolParts: Bool
    let expandEditToolParts: Bool

    private var lastTextPartID: String? {
      items.compactMap { item in
        if case let .part(part) = item,
           part.type == "text",
           !(part.text?.trimmedForInput ?? "").isEmpty
        {
          return part.id
        }
        return nil
      }.last
    }

    private var items: [AssistantRenderItem] {
      let visibleParts = message.parts.filter { part in
        if part.type == "text" {
          return !(part.text?.trimmedForInput ?? "").isEmpty
        }

        if part.type == "reasoning" {
          return showReasoningSummaries && !(part.text?.trimmedForInput ?? "").isEmpty
        }

        guard part.type == "tool" else {
          return false
        }

        if part.tool == "todowrite" || part.tool == "todoread" {
          return false
        }

        if part.tool == "question", part.toolState?.status.isInFlight == true {
          return false
        }

        return true
      }

      var result: [AssistantRenderItem] = []
      var contextBuffer: [MessagePart] = []

      for part in visibleParts {
        if part.isContextTool {
          contextBuffer.append(part)
          continue
        }

        if !contextBuffer.isEmpty {
          result.append(.context(id: contextBuffer[0].id, tools: contextBuffer))
          contextBuffer.removeAll(keepingCapacity: true)
        }

        result.append(.part(part))
      }

      if !contextBuffer.isEmpty {
        result.append(.context(id: contextBuffer[0].id, tools: contextBuffer))
      }

      return result
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        if items.isEmpty {
          Text("(Assistant response has no visible parts yet)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
          switch item {
          case let .part(part):
            AssistantPartView(
              part: part,
              message: message,
              showReasoningSummaries: showReasoningSummaries,
              isLastTextPart: part.id == lastTextPartID,
              turnDurationMs: turnDurationMs,
              expandShellToolParts: expandShellToolParts,
              expandEditToolParts: expandEditToolParts
            )
          case let .context(_, tools):
            ContextToolGroupCard(parts: tools, busy: busy && index == items.count - 1)
          }
        }

        if let errorText = message.info.errorDisplayText {
          Text(errorText)
            .font(.caption)
            .foregroundStyle(.red)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
              RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.red.opacity(0.08))
            )
        }
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Color.white.opacity(0.72))
      )
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Assistant message")
    }
  }

  private enum AssistantRenderItem: Identifiable {
    case part(MessagePart)
    case context(id: String, tools: [MessagePart])

    var id: String {
      switch self {
      case let .part(part):
        return part.id
      case let .context(id, _):
        return "ctx::\(id)"
      }
    }
  }

  private struct AssistantPartView: View {
    let part: MessagePart
    let message: MessageEnvelope
    let showReasoningSummaries: Bool
    let isLastTextPart: Bool
    let turnDurationMs: Double?
    let expandShellToolParts: Bool
    let expandEditToolParts: Bool

    @State private var copied = false

    private var metadata: String {
      assistantMessageMetadata(for: message, turnDurationMs: turnDurationMs)
    }

    private var copyTextValue: String {
      assistantCopyText(for: message, includeReasoning: showReasoningSummaries)
    }

    var body: some View {
      switch part.type {
      case "text":
        if let text = part.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
          VStack(alignment: .leading, spacing: 6) {
            TranscriptMarkdownView(text: text)
              .font(.body)

            if isLastTextPart {
              HStack(spacing: 8) {
                if !metadata.isEmpty {
                  Text(metadata)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Button {
                  copyText(copyTextValue)
                  copied = true
                  DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    copied = false
                  }
                } label: {
                  Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copied ? "Copied" : "Copy")
                .accessibilityIdentifier("message.assistant.copy")
              }
              .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
        }
      case "reasoning":
        if
          showReasoningSummaries,
          let text = part.text?.trimmingCharacters(in: .whitespacesAndNewlines),
          !text.isEmpty
        {
          DisclosureGroup(extractReasoningHeading(from: text) ?? "Reasoning") {
            TranscriptMarkdownView(text: text)
              .font(.subheadline)
              .padding(.top, 6)
          }
        }
      case "tool":
        ToolPartCard(
          part: part,
          expandShellToolParts: expandShellToolParts,
          expandEditToolParts: expandEditToolParts
        )
        .id("\(part.id)::\(expandShellToolParts)::\(expandEditToolParts)")
      default:
        EmptyView()
      }
    }
  }

#endif
