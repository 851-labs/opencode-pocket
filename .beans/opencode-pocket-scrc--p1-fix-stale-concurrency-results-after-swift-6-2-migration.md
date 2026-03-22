---
# opencode-pocket-scrc
title: P1 fix stale concurrency results after Swift 6.2 migration
status: completed
type: bug
priority: high
tags:
    - app
    - concurrency
    - swift-6
    - migration
created_at: 2026-03-22T05:00:28Z
updated_at: 2026-03-22T05:06:27Z
---

Prevent stale async results from older connection and workspace requests from being applied after disconnect, reconnect, or project switching.

Scope:
- Guard `ConnectionStore` async connection completions against late application.
- Guard `WorkspaceStore` async fetch completions against obsolete client and directory context.
- Re-run required validation and only complete once macOS build, iOS build, and SDK tests pass.

Acceptance criteria:
- Disconnecting during connect does not allow late connection state to be applied.
- Workspace fetches do not overwrite current state with responses from a stale client or directory.
- Required repo validation passes.
