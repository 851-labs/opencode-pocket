---
# opencode-pocket-cpty
title: P2 add optional PTY remove parity to OpenCodeSDK
status: scrapped
type: feature
priority: low
tags:
    - sdk
    - client
    - pty
    - optional
created_at: 2026-03-20T23:21:08Z
updated_at: 2026-03-21T00:02:04Z
---

The app client removes PTY sessions in terminal flows, but PTY parity is currently outside the scoped Swift client target.

Scope:
- Add a Swift wrapper for `pty.remove` only if terminal parity is intentionally brought back into scope.
- Keep this Bean as the explicit place where that scope decision is tracked.

Acceptance criteria:
- Either `pty.remove` is implemented and validated, or this Bean is intentionally deferred/cancelled with the scope decision documented.
