#if os(macOS)
import AppKit
import OpenCodeModels
import SwiftUI

struct MacUserMessageCard: View {
  let message: MessageEnvelope

  @State private var copied = false
  @State private var isHovering = false

  private var attachments: [MacMessageAttachment] {
    message.parts.compactMap(MacMessageAttachment.init(part:))
  }

  private var metadata: String {
    macUserMessageMetadata(for: message)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if !attachments.isEmpty {
        MacAttachmentStrip(attachments: attachments)
      }

      MacHighlightedUserText(text: message.textBody)
        .font(.body)

      if isHovering || copied {
        HStack(spacing: 8) {
          if !metadata.isEmpty {
            Text(metadata)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }

          Button {
            macCopyText(message.textBody)
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
        .transition(.opacity)
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .trailing)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.accentColor.opacity(0.16))
    )
    .onHover { hovering in
      isHovering = hovering
    }
    .animation(.easeInOut(duration: 0.15), value: isHovering)
    .animation(.easeInOut(duration: 0.15), value: copied)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("User message")
  }
}

private struct MacHighlightedUserText: View {
  let text: String

  private var highlighted: AttributedString {
    macHighlightedUserText(text)
  }

  var body: some View {
    Text(highlighted)
      .textSelection(.enabled)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct MacAttachmentStrip: View {
  let attachments: [MacMessageAttachment]

  var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 8)], spacing: 8) {
      ForEach(attachments) { attachment in
        if let url = URL(string: attachment.url) {
          Link(destination: url) {
            MacAttachmentThumb(attachment: attachment)
          }
          .buttonStyle(.plain)
        } else {
          MacAttachmentThumb(attachment: attachment)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }
}

private struct MacAttachmentThumb: View {
  let attachment: MacMessageAttachment

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

private struct MacMessageAttachment: Identifiable {
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

private func macHighlightedUserText(_ text: String) -> AttributedString {
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

private func macUserMessageMetadata(for message: MessageEnvelope) -> String {
  var chunks: [String] = []
  if let agent = message.info.agent?.trimmedForInput, !agent.isEmpty {
    chunks.append(agent.capitalized)
  }
  if let model = message.info.modelID?.trimmedForInput, !model.isEmpty {
    chunks.append(model)
  }
  if let time = macFormattedClockTime(from: message.info.createdAt) {
    chunks.append(time)
  }
  return chunks.joined(separator: " · ")
}

private func macFormattedClockTime(from raw: Double?) -> String? {
  guard let raw else {
    return nil
  }

  let seconds = raw > 10_000_000_000 ? raw / 1000 : raw
  let date = Date(timeIntervalSince1970: seconds)
  let formatter = DateFormatter()
  formatter.dateFormat = "h:mm a"
  return formatter.string(from: date)
}

private func macAssistantMessageMetadata(for message: MessageEnvelope) -> String {
  var chunks: [String] = []
  if let model = message.info.modelID?.trimmedForInput, !model.isEmpty {
    chunks.append(model)
  }
  if let time = macFormattedClockTime(from: message.info.createdAt) {
    chunks.append(time)
  }
  return chunks.joined(separator: " · ")
}

private func macAssistantCopyText(for message: MessageEnvelope, includeReasoning: Bool) -> String {
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

func macExtractReasoningHeading(from text: String) -> String? {
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

private func macCopyText(_ text: String) {
  let pasteboard = NSPasteboard.general
  pasteboard.clearContents()
  pasteboard.setString(text, forType: .string)
}

struct MacAssistantMessageCard: View {
  let message: MessageEnvelope
  let busy: Bool
  let showReasoningSummaries: Bool

  @State private var isHovering = false

  private var lastTextPartID: String? {
    groupedParts.compactMap { item in
      if case let .part(part) = item,
        part.type == "text",
        !(part.text?.trimmedForInput ?? "").isEmpty
      {
        return part.id
      }
      return nil
    }.last
  }

  private var groupedParts: [MacAssistantItem] {
    let visibleParts = message.parts.filter { part in
      if part.type != "tool" {
        if part.type == "reasoning" {
          return showReasoningSummaries
        }
        return true
      }

      if part.tool == "todowrite" || part.tool == "todoread" {
        return false
      }

      if part.tool == "question", part.toolState?.status.isInFlight == true {
        return false
      }

      return true
    }

    var result: [MacAssistantItem] = []
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
      if groupedParts.isEmpty {
        Text("(Assistant response has no visible parts yet)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      ForEach(Array(groupedParts.enumerated()), id: \.element.id) { index, item in
        switch item {
        case let .part(part):
          MacAssistantPartView(
            part: part,
            message: message,
            showReasoningSummaries: showReasoningSummaries,
            isLastTextPart: part.id == lastTextPartID,
            showMetadataRow: isHovering
          )
        case let .context(_, tools):
          MacContextToolGroupCard(parts: tools, busy: busy && index == groupedParts.count - 1)
        }
      }

      if let errorText = message.info.errorDisplayText {
        Text(errorText)
          .font(.caption)
          .foregroundStyle(.red)
          .padding(8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(Color.red.opacity(0.08))
          )
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.gray.opacity(0.12))
    )
    .onHover { hovering in
      isHovering = hovering
    }
    .animation(.easeInOut(duration: 0.15), value: isHovering)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Assistant message")
  }
}

private enum MacAssistantItem: Identifiable {
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

private struct MacAssistantPartView: View {
  let part: MessagePart
  let message: MessageEnvelope
  let showReasoningSummaries: Bool
  let isLastTextPart: Bool
  let showMetadataRow: Bool

  @State private var copied = false

  private var metadata: String {
    macAssistantMessageMetadata(for: message)
  }

  private var copyTextValue: String {
    macAssistantCopyText(for: message, includeReasoning: showReasoningSummaries)
  }

  var body: some View {
    switch part.type {
    case "text":
      if let text = part.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
        VStack(alignment: .leading, spacing: 6) {
          RichMarkdownText(text: text)
            .font(.body)

          if isLastTextPart {
            if showMetadataRow || copied {
              HStack(spacing: 8) {
                if !metadata.isEmpty {
                  Text(metadata)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Button {
                  macCopyText(copyTextValue)
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
              .transition(.opacity)
            }
          }
        }
      }
    case "reasoning":
      if
        showReasoningSummaries,
        let text = part.text?.trimmingCharacters(in: .whitespacesAndNewlines),
        !text.isEmpty
      {
        DisclosureGroup(macExtractReasoningHeading(from: text) ?? "Reasoning") {
          RichMarkdownText(text: text)
            .font(.subheadline)
            .padding(.top, 6)
        }
      }
    case "tool":
      MacToolPartCard(part: part)
    default:
      if let rendered = part.renderedText {
        Text(rendered)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}
#endif
