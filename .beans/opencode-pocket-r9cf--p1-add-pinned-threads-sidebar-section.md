---
# opencode-pocket-r9cf
title: P1 add pinned threads section in macOS sidebar
status: completed
type: feature
priority: high
tags:
    - macos
    - sessions
    - sidebar
    - persistence
created_at: 2026-02-26T12:00:00Z
updated_at: 2026-02-26T12:25:00Z
---

Add a right-click pin/unpin action for chat threads in the macOS sidebar and render pinned chats in a dedicated Pins section.

Scope:
- Add local persisted pin state to connection settings.
- Wire pin state through connection and workspace stores.
- Add pin/unpin context menu action on sidebar thread rows.
- Add Pins section above Threads and hide pinned chats from project thread groups.
- Update workspace preview scenarios to include pinned state.

Acceptance criteria:
- Right-clicking a chat thread shows Pin or Unpin based on current state.
- Pinned chats appear in a dedicated Pins section in the macOS sidebar.
- Pinned chats do not appear duplicated in the project Threads list.
- Pin state persists across app restart.
- Required validation passes (macOS build, iOS simulator build, OpenCodeSDK tests).
