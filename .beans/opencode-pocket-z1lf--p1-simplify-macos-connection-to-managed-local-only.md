---
# opencode-pocket-z1lf
title: P1 simplify macOS connection flow to managed local only
status: completed
type: refactor
priority: high
tags:
    - macos
    - connectivity
    - local-server
created_at: 2026-02-25T07:46:30Z
updated_at: 2026-02-25T08:12:10Z
---

Simplify macOS connection behavior by removing local-vs-remote mode switching and always using the managed local OpenCode server runtime.

Scope:
- Remove persisted macOS connection mode from settings.
- Remove macOS mode selection UI from connect/settings views.
- Make macOS auto-connect and manual connect always target managed local runtime.
- Keep iOS remote connection behavior unchanged.

Acceptance criteria:
- macOS connect screen no longer shows remote URL/auth mode toggles.
- macOS `ConnectionStore.connect()` always uses managed local runtime.
- iOS build/test behavior remains unchanged.
- macOS build and iOS tests pass.
