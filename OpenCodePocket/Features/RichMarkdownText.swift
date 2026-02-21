import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - Rich Markdown View

struct RichMarkdownText: View {
  let text: String

  @State private var renderedSegments: [MarkdownSegment] = []
  @State private var pendingRenderTask: Task<Void, Never>?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(renderedSegments) { segment in
        switch segment.kind {
        case let .prose(value):
          MarkdownProseView(text: value)
        case let .code(language, value):
          MarkdownCodeBlockView(language: language, text: value)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onAppear(perform: handleAppear)
    .onChange(of: text) { _, updated in
      handleTextChange(updated)
    }
    .onDisappear(perform: handleDisappear)
  }
}

// MARK: - Rich Markdown Lifecycle

private extension RichMarkdownText {
  func handleAppear() {
    renderedSegments = MarkdownRenderCache.shared.segments(for: text)
  }

  func handleTextChange(_ updated: String) {
    pendingRenderTask?.cancel()
    pendingRenderTask = Task { @MainActor in
      try? await Task.sleep(nanoseconds: 80_000_000)
      guard !Task.isCancelled else {
        return
      }
      renderedSegments = MarkdownRenderCache.shared.segments(for: updated)
    }
  }

  func handleDisappear() {
    pendingRenderTask?.cancel()
    pendingRenderTask = nil
  }
}

// MARK: - Markdown Segment Cache

private final class MarkdownRenderCache {
  static let shared = MarkdownRenderCache()

  private let capacity = 120
  private var cache: [String: [MarkdownSegment]] = [:]
  private var order: [String] = []

  private init() {}

  func segments(for text: String) -> [MarkdownSegment] {
    if let hit = cache[text] {
      return hit
    }

    let parsed = MarkdownSegment.parse(text)
    cache[text] = parsed
    order.append(text)

    if order.count > capacity, let oldest = order.first {
      cache[oldest] = nil
      order.removeFirst()
    }

    return parsed
  }
}

// MARK: - Segment Parsing

private struct MarkdownSegment: Identifiable {
  enum Kind {
    case prose(String)
    case code(language: String?, text: String)
  }

  let id: String
  let kind: Kind

  static func parse(_ source: String) -> [MarkdownSegment] {
    let normalized = source
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
    let lines = normalized.components(separatedBy: "\n")

    var segments: [MarkdownSegment] = []
    var proseLines: [String] = []
    var codeLines: [String] = []
    var language: String?
    var insideFence = false
    var index = 0

    func flushProse() {
      let prose = proseLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
      guard !prose.isEmpty else {
        proseLines.removeAll(keepingCapacity: true)
        return
      }

      segments.append(MarkdownSegment(id: "prose-\(index)", kind: .prose(prose)))
      index += 1
      proseLines.removeAll(keepingCapacity: true)
    }

    func flushCode() {
      let code = codeLines.joined(separator: "\n")
      segments.append(MarkdownSegment(id: "code-\(index)", kind: .code(language: language, text: code)))
      index += 1
      codeLines.removeAll(keepingCapacity: true)
    }

    for line in lines {
      if line.hasPrefix("```") {
        let parsedLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)

        if insideFence {
          flushCode()
          insideFence = false
          language = nil
        } else {
          flushProse()
          insideFence = true
          language = parsedLanguage.isEmpty ? nil : parsedLanguage
        }
        continue
      }

      if insideFence {
        codeLines.append(line)
      } else {
        proseLines.append(line)
      }
    }

    if insideFence {
      flushCode()
    } else {
      flushProse()
    }

    if segments.isEmpty {
      let fallback = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
      if !fallback.isEmpty {
        segments = [MarkdownSegment(id: "prose-0", kind: .prose(fallback))]
      }
    }

    return segments
  }
}

// MARK: - Prose Rendering

private struct MarkdownProseView: View {
  let text: String

  private var attributed: AttributedString? {
    guard var value = try? AttributedString(
      markdown: text,
      options: AttributedString.MarkdownParsingOptions(
        interpretedSyntax: .full,
        failurePolicy: .returnPartiallyParsedIfPossible
      )
    ) else {
      return nil
    }

    linkifyURLs(in: &value)
    return value
  }

  var body: some View {
    Group {
      if let attributed {
        Text(attributed)
      } else {
        Text(text)
      }
    }
    .textSelection(.enabled)
  }
}

// MARK: - URL Linkification

private func linkifyURLs(in attributed: inout AttributedString) {
  let plain = String(attributed.characters)
  guard !plain.isEmpty else {
    return
  }

  guard let regex = try? NSRegularExpression(pattern: #"https?://[^\s)\]>`]+"#) else {
    return
  }

  let nsRange = NSRange(location: 0, length: (plain as NSString).length)
  for match in regex.matches(in: plain, range: nsRange) {
    guard
      let stringRange = Range(match.range, in: plain),
      let attributedRange = Range(stringRange, in: attributed),
      attributed[attributedRange].link == nil
    else {
      continue
    }

    let urlString = String(plain[stringRange])
    guard let url = URL(string: urlString) else {
      continue
    }

    attributed[attributedRange].link = url
  }
}

// MARK: - Code Block Rendering

private struct MarkdownCodeBlockView: View {
  let language: String?
  let text: String

  @State private var copied = false

  private var languageLabel: String {
    guard let language, !language.isEmpty else {
      return "CODE"
    }
    return language.uppercased()
  }

  private var highlightedCode: AttributedString {
    highlightedCodeText(text, language: language)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(languageLabel)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)

        Spacer()

        Button {
          copyCode()
        } label: {
          Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
            .font(.caption2)
        }
        .buttonStyle(.plain)
      }

      ScrollView(.horizontal) {
        Text(highlightedCode)
          .font(.system(.caption, design: .monospaced))
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(10)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color.secondary.opacity(0.08))
    )
  }

  private func copyCode() {
    copyToClipboard(text)
    copied = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      copied = false
    }
  }
}

// MARK: - Syntax Highlighting

private func highlightedCodeText(_ text: String, language: String?) -> AttributedString {
  var attributed = AttributedString(text)
  let lowered = language?.lowercased() ?? ""

  if lowered == "swift" || lowered == "" {
    applyRegexColor(#"\b(let|var|func|if|else|guard|return|await|async|try|throw|struct|class|enum|private|public|internal|extension|import)\b"#, color: .blue, to: &attributed, source: text)
    applyRegexColor(#"\b(true|false|nil)\b"#, color: .purple, to: &attributed, source: text)
  }

  if lowered == "json" {
    applyRegexColor(#""([^"\\]|\\.)*"\s*:"#, color: .blue, to: &attributed, source: text)
    applyRegexColor(#""([^"\\]|\\.)*""#, color: .green, to: &attributed, source: text)
    applyRegexColor(#"\b(true|false|null)\b"#, color: .purple, to: &attributed, source: text)
    applyRegexColor(#"-?\b\d+(\.\d+)?\b"#, color: .orange, to: &attributed, source: text)
  }

  if lowered == "bash" || lowered == "sh" || lowered == "zsh" {
    applyRegexColor(#"\b(if|then|fi|for|in|do|done|case|esac|while|function|export|alias)\b"#, color: .blue, to: &attributed, source: text)
    applyRegexColor(#"\$[A-Za-z_][A-Za-z0-9_]*"#, color: .purple, to: &attributed, source: text)
  }

  return attributed
}

private func applyRegexColor(_ pattern: String, color: Color, to attributed: inout AttributedString, source: String) {
  guard let regex = try? NSRegularExpression(pattern: pattern) else {
    return
  }

  let range = NSRange(location: 0, length: (source as NSString).length)
  for match in regex.matches(in: source, range: range) {
    guard let attributedRange = Range(match.range, in: attributed) else {
      continue
    }
    attributed[attributedRange].foregroundColor = color
  }
}

// MARK: - Clipboard

private func copyToClipboard(_ value: String) {
#if os(macOS)
  let pasteboard = NSPasteboard.general
  pasteboard.clearContents()
  pasteboard.setString(value, forType: .string)
#elseif os(iOS)
  UIPasteboard.general.string = value
#endif
}
