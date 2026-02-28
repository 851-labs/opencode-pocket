---
# opencode-pocket-n8xv
title: P2 rename OpenCodeModels types for clarity
status: completed
type: task
priority: normal
tags:
  - sdk
  - refactor
  - naming
  - swift
created_at: 2026-02-28T07:57:49Z
updated_at: 2026-02-28T07:59:11Z
---

Rename several OpenCodeModels symbols to improve domain clarity in a single breaking-change pass.

Scope:
- Rename `SessionTime` to `SessionTimestamps`
- Rename `MessageInfo` to `MessageMetadata`
- Rename `ToolState` to `ToolExecutionState`
- Rename `QuestionInfo` to `QuestionDefinition`
- Rename `PermissionToolReference` to `ToolCallReference`
- Update all in-repo references across app, SDK, and tests.

Acceptance criteria:
- No remaining references to the old type names in Swift sources.
- macOS build passes.
- iOS simulator build passes.
- `swift test` in `Packages/OpenCodeSDK` passes.
