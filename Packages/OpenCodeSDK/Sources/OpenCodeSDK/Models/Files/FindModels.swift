import Foundation

public struct TextSearchPath: Codable, Hashable, Sendable {
  public let text: String

  public init(text: String) {
    self.text = text
  }
}

public struct TextSearchLines: Codable, Hashable, Sendable {
  public let text: String

  public init(text: String) {
    self.text = text
  }
}

public struct TextSearchMatchText: Codable, Hashable, Sendable {
  public let text: String

  public init(text: String) {
    self.text = text
  }
}

public struct TextSearchSubmatch: Codable, Hashable, Sendable {
  public let match: TextSearchMatchText
  public let start: Int
  public let end: Int

  public init(match: TextSearchMatchText, start: Int, end: Int) {
    self.match = match
    self.start = start
    self.end = end
  }
}

public struct TextSearchMatch: Codable, Hashable, Sendable {
  public let path: TextSearchPath
  public let lines: TextSearchLines
  public let lineNumber: Int
  public let absoluteOffset: Int
  public let submatches: [TextSearchSubmatch]

  enum CodingKeys: String, CodingKey {
    case path
    case lines
    case lineNumber = "line_number"
    case absoluteOffset = "absolute_offset"
    case submatches
  }

  public init(path: TextSearchPath, lines: TextSearchLines, lineNumber: Int, absoluteOffset: Int, submatches: [TextSearchSubmatch]) {
    self.path = path
    self.lines = lines
    self.lineNumber = lineNumber
    self.absoluteOffset = absoluteOffset
    self.submatches = submatches
  }
}

public struct LSPPosition: Codable, Hashable, Sendable {
  public let line: Int
  public let character: Int

  public init(line: Int, character: Int) {
    self.line = line
    self.character = character
  }
}

public struct LSPRange: Codable, Hashable, Sendable {
  public let start: LSPPosition
  public let end: LSPPosition

  public init(start: LSPPosition, end: LSPPosition) {
    self.start = start
    self.end = end
  }
}

public struct SymbolLocation: Codable, Hashable, Sendable {
  public let uri: String
  public let range: LSPRange

  public init(uri: String, range: LSPRange) {
    self.uri = uri
    self.range = range
  }
}

public struct WorkspaceSymbol: Codable, Hashable, Identifiable, Sendable {
  public let name: String
  public let kind: Int
  public let location: SymbolLocation

  public var id: String {
    "\(location.uri)#\(name):\(kind):\(location.range.start.line):\(location.range.start.character)"
  }

  public init(name: String, kind: Int, location: SymbolLocation) {
    self.name = name
    self.kind = kind
    self.location = location
  }
}
