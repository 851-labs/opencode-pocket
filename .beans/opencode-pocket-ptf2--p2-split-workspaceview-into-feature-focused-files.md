---
# opencode-pocket-ptf2
title: P2 split WorkspaceView into feature-focused files under Features/Workspace
status: completed
type: task
priority: normal
tags:
    - swiftui
    - ui-patterns
    - refactor
    - ios
created_at: 2026-02-21T23:01:58Z
updated_at: 2026-02-21T23:40:00Z
---

Apply SwiftUI UI Patterns composition guidance by splitting the oversized iOS workspace file into focused components.

Scope:
- Break `OpenCodePocket/Features/WorkspaceView.swift` into dedicated files (e.g. toolbar/root, transcript, composer, prompts, tool cards).
- Keep each file focused and significantly smaller, with clear ownership and minimal cross-cutting state.
- Preserve existing behavior, accessibility identifiers, and OpenCode parity rendering.

Acceptance criteria:
- No single extracted workspace view file remains monolithic (>~700 lines target).
- Existing UI behavior remains unchanged for sessions, transcript, prompts, and composer.
- iOS tests and macOS build pass.
