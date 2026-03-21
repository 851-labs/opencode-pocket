---
# opencode-pocket-ssei
title: P1 move SDK SSE processing off the caller actor
status: completed
type: task
priority: high
tags:
    - sdk
    - concurrency
    - sse
    - asyncstream
created_at: 2026-03-21T00:21:54Z
updated_at: 2026-03-21T00:25:25Z
---

`OpenCodeClient.subscribeSSE` currently starts its long-lived producer with `Task {}`, which inherits the caller's actor isolation. When called from UI code, reconnect and parsing work can end up running on `MainActor`.

Scope:
- Move the SSE producer off caller actor isolation while keeping the public stream API unchanged.
- Preserve cancellation, retry, and stream termination behavior.
- Keep async-stream lifecycle handling correct and explicit.

Acceptance criteria:
- SSE read, parse, and reconnect work no longer inherits the subscriber's actor.
- Stream cancellation still tears down the underlying work cleanly.
- Existing and new stream-focused tests pass.
