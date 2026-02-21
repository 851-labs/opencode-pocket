import Foundation

public struct SSEMessage: Equatable, Sendable {
  public var id: String?
  public var event: String?
  public var data: String?
  public var retry: Int?

  public init(id: String?, event: String?, data: String?, retry: Int?) {
    self.id = id
    self.event = event
    self.data = data
    self.retry = retry
  }
}

public struct SSEParser {
  private var currentID: String?
  private var currentEvent: String?
  private var currentRetry: Int?
  private var dataBuffer: [String] = []

  public init() {}

  public mutating func ingest(line: String) -> SSEMessage? {
    let normalizedLine = line.removingTrailingCarriageReturns()

    if normalizedLine.isEmpty {
      return flush()
    }

    if normalizedLine.hasPrefix(":") {
      return nil
    }

    let pieces = normalizedLine.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
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
    case "retry":
      if let parsed = Int(value), parsed >= 0 {
        currentRetry = parsed
      }
    default:
      break
    }

    return nil
  }

  public mutating func finish() -> SSEMessage? {
    flush()
  }

  private mutating func flush() -> SSEMessage? {
    guard !dataBuffer.isEmpty || currentID != nil || currentEvent != nil || currentRetry != nil else {
      return nil
    }

    let message = SSEMessage(
      id: currentID,
      event: currentEvent,
      data: dataBuffer.isEmpty ? nil : dataBuffer.joined(separator: "\n"),
      retry: currentRetry
    )

    currentID = nil
    currentEvent = nil
    currentRetry = nil
    dataBuffer.removeAll(keepingCapacity: true)
    return message
  }
}

private extension String {
  func removingTrailingCarriageReturns() -> String {
    var value = self
    while value.last == "\r" {
      value.removeLast()
    }
    return value
  }
}
