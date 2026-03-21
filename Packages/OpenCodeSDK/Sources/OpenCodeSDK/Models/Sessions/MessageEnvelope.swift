import Foundation

public struct MessageEnvelope: Codable, Hashable, Identifiable, Sendable {
  public let info: MessageMetadata
  public let parts: [MessagePart]

  public var id: String { info.id }

  public var textBody: String {
    let merged = parts
      .compactMap(\.renderedText)
      .joined(separator: "\n")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if !merged.isEmpty {
      return merged
    }
    return info.role == .assistant ? "(Assistant response has no text parts yet)" : "(No text content)"
  }

  public init(info: MessageMetadata, parts: [MessagePart]) {
    self.info = info
    self.parts = parts
  }
}
