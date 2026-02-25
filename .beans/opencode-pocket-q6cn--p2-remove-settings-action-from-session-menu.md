---
# opencode-pocket-q6cn
title: P2 remove Settings action from session actions menu
status: completed
type: task
priority: normal
tags:
    - ui
    - settings
    - macos
    - parity
created_at: 2026-02-25T01:55:17Z
updated_at: 2026-02-25T02:06:35Z
---

Remove the "Settings..." action from the macOS workspace session actions menu, since Settings are already available through native app menu access.

Scope:
- Delete the Settings action from the workspace toolbar overflow/session actions menu.
- Keep Rename/Archive/Delete behavior unchanged.
- Keep settings screen and persistence behavior unchanged.

Acceptance criteria:
- Session actions menu no longer contains "Settings...".
- Existing session actions still work.
- macOS build and iOS tests pass after the change.
