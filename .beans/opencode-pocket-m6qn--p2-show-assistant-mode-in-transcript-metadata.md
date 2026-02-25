---
# opencode-pocket-m6qn
title: P2 show assistant mode in transcript metadata
status: completed
type: task
priority: normal
tags:
    - transcript
    - ui
    - parity
    - metadata
created_at: 2026-02-24T23:52:50Z
updated_at: 2026-02-25T01:00:43Z
---

Add assistant mode (for example `Build` / `Plan`) to transcript metadata rows so metadata matches OpenCode desktop structure.

Scope:
- Update assistant metadata formatting for iOS and macOS message cards.
- Include agent/mode label before model and duration.
- Keep existing duration calculation and copy actions unchanged.

Acceptance criteria:
- Assistant metadata displays as `Mode · Model · Duration` when agent is available.
- Rows gracefully omit missing fields without placeholder text.
- Required validation passes (macOS build and iOS tests).
