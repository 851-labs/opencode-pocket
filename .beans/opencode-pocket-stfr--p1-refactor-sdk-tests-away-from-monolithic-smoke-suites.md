---
# opencode-pocket-stfr
title: P1 refactor SDK tests away from monolithic smoke suites
status: completed
type: task
priority: high
tags:
    - sdk
    - testing
    - refactor
    - swift-testing
created_at: 2026-03-21T06:15:00Z
updated_at: 2026-03-22T03:36:42Z
---

`OpenCodeClientTests.swift` has grown into a large mixed smoke suite that makes failures harder to localize and leaves branch-heavy helper logic under-tested.

Scope:
- Split client tests into route-family and behavior-focused Swift Testing suites.
- Extract shared URLProtocol stub helpers into support files.
- Add targeted helper coverage for hot spots like `JSONValue` formatting and request-core edge behavior where feasible.

Acceptance criteria:
- `OpenCodeClientTests.swift` is no longer the single broad smoke bucket for most SDK routes.
- Shared test infrastructure is centralized in support files.
- `swift test`, macOS build, and iOS simulator build pass.
