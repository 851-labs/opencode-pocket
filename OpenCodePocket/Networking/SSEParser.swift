import Foundation

struct SSEMessage: Equatable, Sendable {
  var id: String?
  var event: String?
  var data: String?
}

struct SSEParser {
  private var currentID: String?
  private var currentEvent: String?
  private var dataBuffer: [String] = []

  mutating func ingest(line: String) -> SSEMessage? {
    if line.isEmpty {
      return flush()
    }

    if line.hasPrefix(":") {
      return nil
    }

    let pieces = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
    let field = String(pieces[0])
    var value = pieces.count > 1 ? String(pieces[1]) : ""
    if value.first == " " {
      value.removeFirst()
    }

    switch field {
    case "id":
      currentID = value
    case "event":
      currentEvent = value
    case "data":
      dataBuffer.append(value)
    default:
      break
    }

    return nil
  }

  mutating func finish() -> SSEMessage? {
    flush()
  }

  private mutating func flush() -> SSEMessage? {
    guard !dataBuffer.isEmpty || currentID != nil || currentEvent != nil else {
      return nil
    }

    let message = SSEMessage(
      id: currentID,
      event: currentEvent,
      data: dataBuffer.isEmpty ? nil : dataBuffer.joined(separator: "\n")
    )

    currentID = nil
    currentEvent = nil
    dataBuffer.removeAll(keepingCapacity: true)
    return message
  }
}
