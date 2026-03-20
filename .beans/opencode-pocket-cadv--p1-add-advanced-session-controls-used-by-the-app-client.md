---
# opencode-pocket-cadv
title: P1 add advanced session controls used by the app client
status: completed
type: feature
priority: high
tags:
    - sdk
    - client
    - sessions
    - controls
created_at: 2026-03-20T21:50:45Z
updated_at: 2026-03-20T22:40:51Z
---

After core chat parity lands, the Swift client should support the richer session controls the app client exposes.

Scope:
- Add or complete `session.command`, `session.shell`, `session.abort`, `session.revert`, `session.unrevert`, `session.summarize`, `session.fork`, `session.share`, `session.unshare`, `session.update`, and `session.delete`.
- Keep advanced operations separate from the core session surface so rollout can happen incrementally.
- Add tests for command/shell and session-management behaviors.

Acceptance criteria:
- Advanced session controls used by the app client are available from Swift.
- Core session APIs remain stable while advanced controls are added.
- Required validation passes.
