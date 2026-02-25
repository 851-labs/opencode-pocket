---
# opencode-pocket-r5zp
title: P1 refactor macOS sidebar to threads hierarchy
status: completed
type: feature
priority: high
tags:
    - ui
    - sidebar
    - macos
    - navigation
    - parity
created_at: 2026-02-25T01:57:14Z
updated_at: 2026-02-25T02:06:35Z
---

Refactor the macOS workspace sidebar to a Notes-like thread hierarchy.

Scope:
- Add a top-level "Threads" section in the sidebar.
- Show each project as a collapsible group item under Threads.
- Show each thread/session as a child item inside its project group.
- Preserve existing session selection behavior when choosing a thread item.

Acceptance criteria:
- Sidebar includes a visible Threads section.
- Project rows are collapsible/expandable and persist sensible defaults during the session.
- Thread rows render under their project and selecting one loads that thread.
- macOS build and iOS tests pass after implementation.
