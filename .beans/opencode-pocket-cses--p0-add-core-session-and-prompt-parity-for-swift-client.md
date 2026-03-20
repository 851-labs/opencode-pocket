---
# opencode-pocket-cses
title: P0 add core session and prompt parity for the Swift client
status: todo
type: feature
priority: high
tags:
    - sdk
    - client
    - sessions
    - messages
created_at: 2026-03-20T21:50:45Z
updated_at: 2026-03-20T21:50:45Z
---

The Swift client needs the same core session creation, transcript loading, and prompt submission flow as the app client.

Scope:
- Add or finish wrappers for `session.create`, `session.list`, `session.status`, `session.get`, `session.messages`, and `session.prompt_async`.
- Align session and message models with the fields the app client actually consumes.
- Support transcript loading plus prompt submission without app-side networking gaps.

Acceptance criteria:
- The SDK can drive the app client's core chat lifecycle in Swift.
- Session and message models cover the fields needed for list/detail/transcript rendering.
- Required validation passes.
