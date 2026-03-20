---
# opencode-pocket-swt1
title: P2 add Swift Testing support primitives and migrate parser and normalization suites
status: completed
type: task
priority: normal
tags:
    - testing
    - sdk
    - networking
created_at: 2026-03-19T00:00:00Z
updated_at: 2026-03-19T22:32:00Z
---

Establish Swift Testing support inside `OpenCodeSDK` and migrate the lowest-risk parser and normalization suites first so the package has a clear local pattern for later conversions.

Scope:
- Add any shared Swift Testing support needed in `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests`.
- Migrate `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/SSEParserTests.swift` to Swift Testing.
- Migrate `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/MessageEventNormalizationTests.swift` to Swift Testing.

Acceptance criteria:
- The migrated suites use `struct` test suites, `@Test`, `#expect`, and `#require` where appropriate.
- No `XCTestCase` or `XCTAssert*` remain in the migrated files.
- Any shared test helpers compile cleanly and follow project conventions.
- Required validation passes (macOS build, iOS simulator build, OpenCodeSDK tests).

Completed with a shared `.networking` tag helper plus Swift Testing migrations for the SSE parser and message normalization suites. Required validation passed.
