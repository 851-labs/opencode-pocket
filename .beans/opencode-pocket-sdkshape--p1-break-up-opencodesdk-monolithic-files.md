---
# opencode-pocket-sdkshape
title: P1 break up OpenCodeSDK monolithic files
status: completed
type: feature
priority: high
tags:
    - sdk
    - refactor
    - maintainability
    - structure
created_at: 2026-03-21T05:55:08Z
updated_at: 2026-03-21T06:06:49Z
---

Several SDK source files have grown large enough to hurt readability and reviewability, especially `OpenCodeClient.swift` and the larger model files.

Scope:
- Split oversized files into smaller domain-focused files without changing public API behavior.
- Preserve the existing `OpenCodeSDK` module and current type names.
- Keep the refactor mechanical and low-risk.

Acceptance criteria:
- The largest SDK files are broken into clearer units.
- `swift test`, macOS build, and iOS simulator build pass.
- No public API behavior changes are introduced.
