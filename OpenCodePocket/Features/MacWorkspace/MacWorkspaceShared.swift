#if os(macOS)
  import SwiftUI

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
