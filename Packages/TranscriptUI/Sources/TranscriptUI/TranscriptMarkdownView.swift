import SwiftUI
import Textual

public struct TranscriptMarkdownView: View {
  public let text: String

  public init(text: String) {
    self.text = text
  }

  public var body: some View {
    StructuredText(markdown: text)
      .textual.structuredTextStyle(.transcript)
      .textual.listItemSpacing(.fontScaled(top: 0.15, bottom: 0.15))
      .textual.textSelection(.enabled)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
