---
# opencode-pocket-swt4
title: P2 migrate live SDK integration tests to Swift Testing traits and tags
status: completed
type: task
priority: normal
tags:
    - testing
    - sdk
    - networking
    - integration
created_at: 2026-03-19T00:00:00Z
updated_at: 2026-03-19T22:49:00Z
---

Migrate the live server integration coverage to Swift Testing while preserving the existing environment-gated contract for optional live execution.

Scope:
- Migrate `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/LiveServerIntegrationTests.swift` to Swift Testing.
- Preserve env-based gating and make the live nature of the suite explicit with tags or traits where appropriate.

Acceptance criteria:
- The suite no longer depends on `XCTestCase`, `XCTSkip`, or `XCTAssert*`.
- Default local `swift test` runs keep live coverage disabled unless the expected environment is configured.
- The live test contract documented in `AGENTS.md` remains intact.
- Required validation passes (macOS build, iOS simulator build, OpenCodeSDK tests).

Completed by migrating the live integration suite to Swift Testing with explicit `.live` tagging and env-based enablement, while preserving the existing live-test contract. Required validation passed.
