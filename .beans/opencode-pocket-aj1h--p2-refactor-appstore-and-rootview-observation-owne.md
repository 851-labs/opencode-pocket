---
# opencode-pocket-aj1h
title: P2 refactor AppStore and RootView observation ownership
status: completed
type: task
priority: normal
tags:
    - refactor
    - swiftui
    - observation
created_at: 2026-02-21T22:38:51Z
updated_at: 2026-02-21T22:44:14Z
---

Apply strict Observation ownership guidance by removing nested @Observable composition patterns and aligning root view/store wiring.

Scope:
- Rework AppStore/RootView/OpenCodePocketApp composition so observable ownership is explicit and non-redundant.
- Ensure @State is used only at root ownership boundaries and child views receive concrete dependencies.
- Keep behavior unchanged (connection flow, mock workspace boot, settings access).

Acceptance criteria:
- No nested @Observable ownership anti-pattern in app composition.
- Build and runtime behavior unchanged for connect/workspace switching.
- macOS build and iOS tests pass.
