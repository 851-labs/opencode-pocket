import Foundation
import OpenCodeSDK
import Testing

struct JSONValueTests {
  @Test func compactDescriptionPrefersObjectMessage() {
    let value: JSONValue = .object([
      "message": .string("boom"),
      "code": .number(500),
    ])

    #expect(value.compactDescription == "boom")
  }

  @Test func compactDescriptionFormatsNestedCollections() {
    let value: JSONValue = .object([
      "array": .array([.string("a"), .bool(true)]),
      "flag": .bool(false),
      "empty": .null,
    ])

    let description = value.compactDescription
    #expect(description.contains("array: a, true") == true)
    #expect(description.contains("flag: false") == true)
    #expect(description.contains("empty: null") == true)
  }

  @Test func decodedHelperRoundTripsTypedPayload() throws {
    let value: JSONValue = .object([
      "id": .string("perm_1"),
      "sessionID": .string("ses_1"),
      "permission": .string("edit"),
      "patterns": .array([.string("src/**")]),
      "metadata": .object(["tool": .string("edit")]),
      "always": .array([]),
      "tool": .object(["messageID": .string("msg_1"), "callID": .string("call_1")]),
    ])

    let decoded = value.decoded(as: PermissionRequest.self)
    let request = try #require(decoded)

    #expect(request.id == "perm_1")
    #expect(request.patterns == ["src/**"])
  }

  @Test func boolNullAndDoubleValuesRoundTrip() throws {
    let values: [JSONValue] = [
      .bool(true),
      .null,
      .number(1.5),
    ]

    let encoded = try values.map { try JSONEncoder().encode($0) }
    let decoded = try encoded.map { try JSONDecoder().decode(JSONValue.self, from: $0) }

    #expect(decoded[0].boolValue == true)
    #expect(decoded[1].compactDescription == "null")
    #expect(decoded[2].doubleValue == 1.5)
    #expect(decoded[1].arrayValue == nil)
    #expect(decoded[1].boolValue == nil)
  }

  @Test func arrayBoolAndNumberAccessorsReturnExpectedValues() {
    let array: JSONValue = .array([.string("a")])
    let bool: JSONValue = .bool(false)
    let number: JSONValue = .number(42)
    let string: JSONValue = .string("hello")

    #expect(array.arrayValue?.count == 1)
    #expect(bool.boolValue == false)
    #expect(number.doubleValue == 42)
    #expect(string.doubleValue == nil)
  }

  @Test func unsupportedDecoderShapeThrowsDataCorrupted() {
    do {
      _ = try JSONValue(from: UnsupportedValueDecoder())
      Issue.record("Expected unsupported JSONValue decoder to throw")
    } catch let error as DecodingError {
      #expect(String(describing: error).contains("Unsupported JSON type") == true)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

private struct UnsupportedValueDecoder: Decoder {
  var codingPath: [CodingKey] { [] }
  var userInfo: [CodingUserInfoKey: Any] { [:] }

  func container<Key>(keyedBy _: Key.Type) throws -> KeyedDecodingContainer<Key> {
    throw DecodingError.typeMismatch([String: String].self, .init(codingPath: [], debugDescription: "unsupported"))
  }

  func unkeyedContainer() throws -> UnkeyedDecodingContainer {
    throw DecodingError.typeMismatch([String].self, .init(codingPath: [], debugDescription: "unsupported"))
  }

  func singleValueContainer() throws -> SingleValueDecodingContainer {
    UnsupportedValueContainer()
  }
}

private struct UnsupportedValueContainer: SingleValueDecodingContainer {
  var codingPath: [CodingKey] { [] }

  func decodeNil() -> Bool { false }
  func decode(_: Bool.Type) throws -> Bool { try throwMismatch() }
  func decode(_: String.Type) throws -> String { try throwMismatch() }
  func decode(_: Double.Type) throws -> Double { try throwMismatch() }
  func decode(_: Float.Type) throws -> Float { try throwMismatch() }
  func decode(_: Int.Type) throws -> Int { try throwMismatch() }
  func decode(_: Int8.Type) throws -> Int8 { try throwMismatch() }
  func decode(_: Int16.Type) throws -> Int16 { try throwMismatch() }
  func decode(_: Int32.Type) throws -> Int32 { try throwMismatch() }
  func decode(_: Int64.Type) throws -> Int64 { try throwMismatch() }
  func decode(_: UInt.Type) throws -> UInt { try throwMismatch() }
  func decode(_: UInt8.Type) throws -> UInt8 { try throwMismatch() }
  func decode(_: UInt16.Type) throws -> UInt16 { try throwMismatch() }
  func decode(_: UInt32.Type) throws -> UInt32 { try throwMismatch() }
  func decode(_: UInt64.Type) throws -> UInt64 { try throwMismatch() }
  func decode<T>(_: T.Type) throws -> T where T: Decodable { try throwMismatch() }

  private func throwMismatch<T>() throws -> T {
    throw DecodingError.typeMismatch(T.self, .init(codingPath: [], debugDescription: "unsupported"))
  }
}
