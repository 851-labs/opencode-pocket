---
# opencode-pocket-2qgb
title: P3 add pin icons to pinned sidebar rows
status: completed
type: task
priority: low
tags:
    - macos
    - sidebar
    - sessions
    - iconography
    - pins
created_at: 2026-02-27T05:06:46Z
updated_at: 2026-02-27T17:06:00Z
---

Add a pin icon to rows in the Pins section of the macOS sidebar so pinned sessions are visually distinct.

Scope:
- Update pinned-row icon rendering in MacWorkspaceSidebar.
- Keep existing pin/unpin context-menu behavior unchanged.
- Preserve row spacing/alignment and running-state indicator behavior.

Acceptance criteria:
- Rows under Pins show a pin icon.
- Thread rows in project sections remain unchanged.
- Active/running rows still render correctly.
- Required validation passes (macOS build, iOS simulator build, OpenCodeSDK tests).
