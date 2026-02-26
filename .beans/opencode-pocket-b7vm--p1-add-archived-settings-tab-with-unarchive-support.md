---
# opencode-pocket-b7vm
title: P1 add archived settings tab with true unarchive support
status: completed
type: feature
priority: high
tags:
    - settings
    - macos
    - sessions
    - api
created_at: 2026-02-26T10:30:00Z
updated_at: 2026-02-26T10:50:00Z
---

Add a new macOS Settings experience for archived threads and support true unarchive semantics in Pocket by sending `time.archived = null` in session update requests.

Scope:
- Add archived sessions tab in `FeaturesV2/Settings/MacSettings`.
- Add per-row unarchive action and empty state.
- Extend SDK models/request encoding to support explicit null for archived time.
- Add workspace-store unarchive flow and archived session helpers.
- Add preview scenarios for archived and empty states.

Acceptance criteria:
- Settings includes a dedicated archived tab with list + unarchive action.
- Unarchive requests encode archived as explicit JSON null.
- Unsupported server responses produce a clear compatibility error message.
- Required validation passes (macOS build, iOS simulator build, OpenCodeSDK tests).
