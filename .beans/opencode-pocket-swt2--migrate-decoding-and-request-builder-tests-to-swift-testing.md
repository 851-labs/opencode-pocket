---
# opencode-pocket-swt2
title: P2 migrate decoding and request builder tests to Swift Testing
status: todo
type: task
priority: normal
tags:
    - testing
    - sdk
    - networking
    - decoding
created_at: 2026-03-19T00:00:00Z
updated_at: 2026-03-19T00:00:00Z
---

Migrate the deterministic decoding and request builder suites to Swift Testing once the initial package-local conventions are in place.

Scope:
- Migrate `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/JSONDecodingTests.swift` to Swift Testing.
- Migrate `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/RequestBuilderTests.swift` to Swift Testing.
- Use modern Swift Testing error assertions such as `#expect(throws:)` where they improve clarity.

Acceptance criteria:
- The migrated suites use Swift Testing APIs instead of XCTest.
- Error assertions use `#expect(throws:)`, `Issue.record()`, and `#require` appropriately.
- No production behavior changes are needed for these suites.
- Required validation passes (macOS build, iOS simulator build, OpenCodeSDK tests).
