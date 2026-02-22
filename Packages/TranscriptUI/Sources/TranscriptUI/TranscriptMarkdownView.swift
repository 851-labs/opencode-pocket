import SwiftUI
import Textual

public struct TranscriptMarkdownView: View {
  public let text: String

  public init(text: String) {
    self.text = text
  }

  public var body: some View {
    StructuredText(markdown: text)
      .textual.structuredTextStyle(.default)
      .textual.textSelection(.enabled)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
