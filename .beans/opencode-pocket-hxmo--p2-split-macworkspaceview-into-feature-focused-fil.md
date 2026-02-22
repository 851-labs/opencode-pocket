---
# opencode-pocket-hxmo
title: P2 split MacWorkspaceView into feature-focused files under Features/MacWorkspace
status: completed
type: task
priority: normal
tags:
    - swiftui
    - ui-patterns
    - refactor
    - macos
created_at: 2026-02-21T23:02:13Z
updated_at: 2026-02-22T02:06:00Z
---

Apply SwiftUI UI Patterns composition guidance by splitting the oversized macOS workspace file into focused components.

Scope:
- Break `OpenCodePocket/Features/MacWorkspaceView.swift` into dedicated files (sidebar/detail shell, transcript, composer, settings tab, prompt cards, tool cards).
- Keep file boundaries aligned with interaction models and ownership, minimizing giant helper clusters in one file.
- Preserve parity behavior and existing accessibility identifiers.

Acceptance criteria:
- Mac workspace code is distributed into focused feature files with clear responsibilities.
- Behavior for project sections, transcript controls, composer, and settings remains unchanged.
- macOS build and iOS tests pass.
