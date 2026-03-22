import SwiftUI
import Textual

struct TranscriptStructuredTextStyle: StructuredText.Style {
  let inlineStyle: InlineStyle = InlineStyle.gitHub
    .code(.monospaced, .fontScale(0.9), .backgroundColor(Color.secondary.opacity(0.14)))
    .link(.foregroundColor(.accentColor))

  let headingStyle: StructuredText.GitHubHeadingStyle = .gitHub
  let paragraphStyle: StructuredText.GitHubParagraphStyle = .gitHub
  let blockQuoteStyle: StructuredText.GitHubBlockQuoteStyle = .gitHub
  let codeBlockStyle: TranscriptCodeBlockStyle = .init()
  let listItemStyle: StructuredText.DefaultListItemStyle = .init(markerSpacing: .fontScaled(0.6))
  let unorderedListMarker: StructuredText.HierarchicalSymbolListMarker = .hierarchical(.disc, .circle, .square)
  let orderedListMarker: StructuredText.DecimalListMarker = .decimal
  let tableStyle: StructuredText.GitHubTableStyle = .gitHub
  let tableCellStyle: StructuredText.GitHubTableCellStyle = .gitHub
  let thematicBreakStyle: StructuredText.GitHubThematicBreakStyle = .gitHub
}

struct TranscriptCodeBlockStyle: StructuredText.CodeBlockStyle {
  @State private var copied = false

  func makeBody(configuration: Configuration) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Text(languageLabel(configuration.languageHint))
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)

        Spacer()

        Button {
          configuration.codeBlock.copyToPasteboard()
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
        .accessibilityLabel(copied ? "Copied" : "Copy code")
      }
      .padding(.horizontal, 10)
      .padding(.top, 10)

      Overflow {
        configuration.label
          .textual.lineSpacing(.fontScaled(0.22))
          .textual.fontScale(0.88)
          .fixedSize(horizontal: false, vertical: true)
          .monospaced()
          .padding(.horizontal, 10)
          .padding(.bottom, 10)
      }
    }
    .background(Color.secondary.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
    )
    .textual.blockSpacing(.fontScaled(top: 0.7, bottom: 0.05))
  }

  private func languageLabel(_ hint: String?) -> String {
    guard let hint = hint?.trimmingCharacters(in: .whitespacesAndNewlines), !hint.isEmpty else {
      return "CODE"
    }
    return hint.uppercased()
  }
}

extension StructuredText.Style where Self == TranscriptStructuredTextStyle {
  static var transcript: Self {
    .init()
  }
}
