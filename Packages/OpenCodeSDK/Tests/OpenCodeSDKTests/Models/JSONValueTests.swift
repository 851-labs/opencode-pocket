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
  }
}
