---
# opencode-pocket-sx2q
title: P2 split MacWorkspaceView into focused sections and extracted subviews
status: completed
type: task
priority: normal
tags:
    - refactor
    - swiftui
    - macos
    - transcript
created_at: 2026-02-21T22:39:13Z
updated_at: 2026-02-21T22:50:02Z
---

Refactor `OpenCodePocket/Features/MacWorkspaceView.swift` to align with strict SwiftUI ordering and large-view decomposition rules.

Scope:
- Reorder top-level declarations consistently (environment, lets, state, computed vars, body, subviews, helpers).
- Extract complex sidebar/detail/toolbar/settings/transcript segments into focused private view types or marked extensions.
- Preserve behavior and accessibility identifiers for session/project navigation, actions menu, composer, and transcript controls.

Acceptance criteria:
- Mac workspace file is structurally decomposed and easier to navigate.
- No functional regressions in project sections, settings access, or transcript interactions.
- macOS build and iOS tests pass.
