---
# opencode-pocket-c4tr
title: P2 move macOS session actions to row context menu
status: completed
type: task
priority: medium
tags:
    - refactor
    - swiftui
    - macos
    - ux
created_at: 2026-02-25T15:05:00Z
updated_at: 2026-02-25T15:07:00Z
---

Remove session action controls from the macOS workspace toolbar and provide rename/archive/delete on the session row context menu.

Scope:
- Remove the toolbar session actions menu.
- Add right-click context menu actions on sidebar session rows.
- Ensure actions target the right-clicked row, even when another row is selected.
- Keep refresh/create toolbar actions unchanged.

Acceptance criteria:
- Toolbar no longer shows rename/archive/delete menu.
- Sidebar session rows expose rename/archive/delete via context menu.
- Delete confirmation and rename/archive actions operate on clicked row ID.
- macOS + iOS builds and OpenCodeSDK tests pass.
