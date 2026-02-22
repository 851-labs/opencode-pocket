import Foundation

enum TranscriptMarkdownFixtures {
  static let timeline = """
  From our best current science, here is the short version:

  - About 13.8 billion years ago, the universe began in a hot, dense state (the Big Bang).
  - In the first tiny fractions of a second, space expanded extremely fast (inflation), then cooled.
  - Within minutes, the first simple nuclei formed (mostly hydrogen and helium).
  - After about 380,000 years, atoms formed and light could travel freely.
  - Over billions of years, stars and galaxies formed and evolved.
  """

  static let nestedLists = """
  ## Launch Checklist

  1. Validate API behavior
     1. Confirm auth headers
     1. Verify SSE reconnect
  1. Verify UI contracts
     - Transcript list markers render
     - Code blocks preserve copy affordances
     - Links remain interactive
  """

  static let mixed = """
  > Outside of a dog, a book is man's best friend.

  Use `git status` before pushing and review docs at https://swift.org.

  ```swift
  struct LaunchPlan {
    let title: String
    let isReady: Bool
  }
  ```
  """

  static let table = """
  | Era | Approximate Time |
  | --- | --- |
  | Big Bang | 13.8B years ago |
  | Recombination | 380K years |
  | First stars | ~100M years |
  """

  static let reasoning = """
  ### Reasoning Summary

  1. Gather observable constraints.
  2. Cross-check with known cosmology milestones.
  3. Return concise bullets with confidence notes.
  """
}

#if DEBUG
import SwiftUI

private struct TranscriptMarkdownPreviewDeck: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        TranscriptMarkdownView(text: TranscriptMarkdownFixtures.timeline)
        TranscriptMarkdownView(text: TranscriptMarkdownFixtures.nestedLists)
        TranscriptMarkdownView(text: TranscriptMarkdownFixtures.mixed)
        TranscriptMarkdownView(text: TranscriptMarkdownFixtures.table)
        TranscriptMarkdownView(text: TranscriptMarkdownFixtures.reasoning)
      }
      .padding(20)
      .frame(maxWidth: 860, alignment: .leading)
    }
    .frame(minWidth: 700, minHeight: 760)
  }
}

#Preview("Transcript Markdown Fixtures") {
  TranscriptMarkdownPreviewDeck()
}
#endif
