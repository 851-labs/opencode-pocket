---
# opencode-pocket-n3vd
title: P2 remove reasoning summaries toggle from session actions menu
status: todo
type: task
priority: normal
tags:
    - ui
    - settings
    - macos
    - parity
created_at: 2026-02-25T01:43:08Z
updated_at: 2026-02-25T01:43:08Z
---

Remove the "Show Reasoning Summaries" toggle from the macOS workspace session actions menu and keep this setting controlled only from Settings.

Scope:
- Delete the toggle from the session actions overflow menu in the macOS workspace toolbar.
- Preserve existing Rename/Archive/Delete/Settings actions.
- Keep settings persistence and behavior unchanged.

Acceptance criteria:
- Session actions menu no longer shows "Show Reasoning Summaries".
- Reasoning summaries can still be managed via Settings.
- macOS build and iOS tests pass after the change.
