---
# opencode-pocket-swt3
title: P1 refactor OpenCodeClientTests for Swift Testing isolation and deterministic async behavior
status: in_progress
type: task
priority: high
tags:
    - testing
    - sdk
    - networking
    - async
created_at: 2026-03-19T00:00:00Z
updated_at: 2026-03-19T22:34:00Z
---

Migrate `OpenCodeClientTests` to Swift Testing and remove the shared global test harness patterns that would become unsafe or flaky under parallel execution.

Scope:
- Migrate `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/OpenCodeClientTests.swift` to Swift Testing.
- Replace shared global stub state with per-test or otherwise isolated test infrastructure.
- Replace timing-based cancellation assertions with deterministic synchronization.
- Remove the real-network cancellation dependency from the suite.

Acceptance criteria:
- The suite runs under Swift Testing without `XCTestCase`, `setUp`, `tearDown`, or `XCTAssert*`.
- Shared mutable test state no longer allows cross-test interference under parallel execution.
- Cancellation and reconnect assertions are deterministic rather than sleep-based.
- Required validation passes (macOS build, iOS simulator build, OpenCodeSDK tests).
