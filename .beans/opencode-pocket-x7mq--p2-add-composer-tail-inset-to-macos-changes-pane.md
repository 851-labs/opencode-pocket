---
# opencode-pocket-x7mq
title: P2 apply composer bottom inset to macOS changes pane
status: in_progress
type: task
priority: normal
tags:
    - ui
    - macos
    - changes
    - composer
created_at: 2026-02-25T01:43:44Z
updated_at: 2026-02-25T01:50:55Z
---

Apply the same bottom-inset spacing strategy used by transcript to the macOS Changes pane so diff rows can scroll above the overlaid composer.

Scope:
- Pass computed composer bottom inset into the changes pane.
- Add bottom spacer content in the changes list to keep last row visible.
- Preserve existing diff row rendering.

Acceptance criteria:
- Last diff row can scroll fully above the composer overlay.
- Changes pane layout remains unchanged aside from tail spacing.
- macOS build and iOS tests pass.
