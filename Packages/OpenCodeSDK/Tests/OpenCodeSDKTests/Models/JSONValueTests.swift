import Foundation
import OpenCodeSDK
import Testing

@Suite(.tags(.networking))
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
}
