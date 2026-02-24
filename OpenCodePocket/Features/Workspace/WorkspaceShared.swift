import SwiftUI

#if os(iOS)
  import UIKit

  func copyText(_ text: String) {
    UIPasteboard.general.string = text
  }

  extension String {
    var trimmedForInput: String {
      trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }

  extension Array {
    subscript(safe index: Index) -> Element? {
      guard indices.contains(index) else {
        return nil
      }
      return self[index]
    }
  }

#endif
