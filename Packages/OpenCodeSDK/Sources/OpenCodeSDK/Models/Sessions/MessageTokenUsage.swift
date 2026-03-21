import Foundation

public struct MessageTokenUsage: Codable, Hashable, Sendable {
  public struct CacheUsage: Codable, Hashable, Sendable {
    public let read: Int
    public let write: Int

    public init(read: Int = 0, write: Int = 0) {
      self.read = read
      self.write = write
    }

    public init(from decoder: Decoder) throws {
      let raw = try JSONValue(from: decoder)
      guard let object = raw.objectValue else {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Token cache usage is not an object"))
      }

      read = object.int(for: "read") ?? 0
      write = object.int(for: "write") ?? 0
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(read, forKey: .read)
      try container.encode(write, forKey: .write)
    }

    private enum CodingKeys: String, CodingKey {
      case read
      case write
    }
  }

  public let total: Int?
  public let input: Int
  public let output: Int
  public let reasoning: Int
  public let cache: CacheUsage

  public var contextUsageTotal: Int {
    input + output + reasoning + cache.read + cache.write
  }

  public init(total: Int? = nil, input: Int = 0, output: Int = 0, reasoning: Int = 0, cache: CacheUsage = CacheUsage()) {
    self.total = total
    self.input = input
    self.output = output
    self.reasoning = reasoning
    self.cache = cache
  }

  public init(from decoder: Decoder) throws {
    let raw = try JSONValue(from: decoder)
    guard let object = raw.objectValue else {
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Token usage is not an object"))
    }

    total = object.int(for: "total")
    input = object.int(for: "input") ?? 0
    output = object.int(for: "output") ?? 0
    reasoning = object.int(for: "reasoning") ?? 0

    if let cacheObject = object.object(for: "cache") {
      cache = CacheUsage(read: cacheObject.int(for: "read") ?? 0, write: cacheObject.int(for: "write") ?? 0)
    } else {
      cache = CacheUsage()
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(total, forKey: .total)
    try container.encode(input, forKey: .input)
    try container.encode(output, forKey: .output)
    try container.encode(reasoning, forKey: .reasoning)
    try container.encode(cache, forKey: .cache)
  }

  private enum CodingKeys: String, CodingKey {
    case total
    case input
    case output
    case reasoning
    case cache
  }
}
