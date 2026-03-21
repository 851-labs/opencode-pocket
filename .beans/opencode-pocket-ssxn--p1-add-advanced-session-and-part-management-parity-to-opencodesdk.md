---
# opencode-pocket-ssxn
title: P1 add advanced session and part management parity to OpenCodeSDK
status: todo
type: feature
priority: high
tags:
    - sdk
    - parity
    - sessions
    - messages
created_at: 2026-03-21T04:48:08Z
updated_at: 2026-03-21T04:48:08Z
---

The current SDK covers core session flow, but several important non-TUI session lifecycle and message-editing routes remain unimplemented.

Scope:
- Add `session.children`, `session.deleteMessage`, `session.fork`, `session.init`, `session.share`, and `session.unshare`.
- Add `part.update` and `part.delete` using the existing message part model where possible.
- Introduce only the request models needed to encode these routes cleanly.

Acceptance criteria:
- Advanced session management and part editing routes are available through `OpenCodeClient`.
- Tests cover path construction, body encoding, and representative decode paths.
- Required validation passes before completion.
