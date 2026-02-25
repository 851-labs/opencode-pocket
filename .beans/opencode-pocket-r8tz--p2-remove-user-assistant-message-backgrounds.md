---
# opencode-pocket-r8tz
title: P2 remove user and assistant message backgrounds
status: completed
type: task
priority: normal
tags:
    - ui
    - transcript
    - parity
    - styling
created_at: 2026-02-25T00:19:52Z
updated_at: 2026-02-25T01:08:29Z
---

Remove the card-style background fills from user and assistant transcript messages to match OpenCode desktop styling.

Scope:
- Remove user message background treatment in iOS and macOS transcript cards.
- Remove assistant message background treatment in iOS and macOS transcript cards.
- Preserve spacing, typography, copy actions, and metadata row behavior.

Acceptance criteria:
- User and assistant messages render without rounded background containers on iOS and macOS.
- Transcript remains readable with consistent vertical rhythm after style change.
- macOS build and iOS tests pass.
