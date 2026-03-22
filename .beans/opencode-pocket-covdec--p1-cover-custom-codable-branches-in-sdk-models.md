---
# opencode-pocket-covdec
title: P1 cover custom Codable branches in SDK models
status: completed
type: task
priority: high
tags:
    - sdk
    - testing
    - coverage
    - codable
created_at: 2026-03-22T05:39:31Z
updated_at: 2026-03-22T05:52:20Z
---

The remaining coverage gap includes several custom `Codable` implementations with alternate decode branches, unknown-case fallbacks, and shape-dependent encoding logic.

Scope:
- Add targeted tests for:
  - `Models/Sessions/MessageFailure.swift`
  - `Models/Sessions/MessageTokenUsage.swift`
  - `Models/Sessions/SessionStatus.swift`
  - `Models/Providers/AuthModels.swift`
  - `Models/Tools/MCPModels.swift`
  - `Models/Tools/CommandModels.swift`
- Cover unknown enum values, missing/optional fields, coding-key remaps, and encode/decode round trips.

Acceptance criteria:
- Custom Codable branches are covered by focused tests rather than incidental route coverage.
- Unknown/fallback behavior is explicitly verified.
- Required validation passes before completion.
