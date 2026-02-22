import SwiftUI
import Textual

struct TranscriptStructuredTextStyle: StructuredText.Style {
  let inlineStyle: InlineStyle = InlineStyle.gitHub
    .code(.monospaced, .fontScale(0.9), .backgroundColor(Color.secondary.opacity(0.14)))
    .link(.foregroundColor(.accentColor))

  let headingStyle: StructuredText.GitHubHeadingStyle = .gitHub
  let paragraphStyle: StructuredText.GitHubParagraphStyle = .gitHub
  let blockQuoteStyle: StructuredText.GitHubBlockQuoteStyle = .gitHub
  let codeBlockStyle: StructuredText.GitHubCodeBlockStyle = .gitHub
  let listItemStyle: StructuredText.DefaultListItemStyle = .init(markerSpacing: .fontScaled(0.6))
  let unorderedListMarker: StructuredText.HierarchicalSymbolListMarker = .hierarchical(.disc, .circle, .square)
  let orderedListMarker: StructuredText.DecimalListMarker = .decimal
  let tableStyle: StructuredText.GitHubTableStyle = .gitHub
  let tableCellStyle: StructuredText.GitHubTableCellStyle = .gitHub
  let thematicBreakStyle: StructuredText.GitHubThematicBreakStyle = .gitHub
}

extension StructuredText.Style where Self == TranscriptStructuredTextStyle {
  static var transcript: Self {
    .init()
  }
}
