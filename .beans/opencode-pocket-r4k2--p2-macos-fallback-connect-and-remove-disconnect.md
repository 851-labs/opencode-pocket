---
# opencode-pocket-r4k2
title: P2 macOS connect fallback only and remove disconnect action
status: completed
type: refactor
priority: medium
tags:
  - macos
  - ux
  - connectivity
created_at: 2026-02-25T08:24:00Z
updated_at: 2026-02-25T10:02:00Z
---

Adjust macOS connection UX after moving to managed-local defaults.

Scope:
- Keep workspace visible during startup and reconnect attempts.
- Show MacConnectView only as a failure fallback when disconnected and not connecting.
- Remove the macOS disconnect toolbar action.

Acceptance criteria:
- macOS no longer lands on the connect waiting screen during normal startup.
- macOS disconnect button is removed from the workspace toolbar.
- Failed local startup still has a visible fallback path.
- macOS build and iOS tests pass.
