---
# opencode-pocket-srem
title: P1 close remaining non-TUI opencode OpenAPI gaps in OpenCodeSDK
status: completed
type: feature
priority: high
tags:
    - sdk
    - parity
    - openapi
    - follow-up
created_at: 2026-03-21T04:48:08Z
updated_at: 2026-03-21T05:08:09Z
---

`OpenCodeSDK` now covers the core app-client surface, but several meaningful non-TUI OpenAPI routes still remain uncovered.

Scope:
- Coordinate the child Beans `srch`, `ssxn`, `maut`, `ssup`, and `sgit`.
- Keep this track focused on non-TUI, non-PTY, non-CLI routes that materially improve the Swift SDK.
- Preserve the current package split between `OpenCodeModels` and `OpenCodeNetworking`, and keep endpoint wrappers thin.

Acceptance criteria:
- Must-have and nice-to-have child Beans are completed and validated.
- The remaining non-TUI surface is substantially closer to OpenAPI parity without broadening into TUI or PTY scope.
- Required validation passes before completion.
