---
# opencode-pocket-cpar
title: P0 achieve Swift client parity with the OpenCode app client
status: in_progress
type: feature
priority: high
tags:
    - sdk
    - client
    - parity
    - networking
created_at: 2026-03-20T21:50:45Z
updated_at: 2026-03-20T22:40:51Z
---

`OpenCodeSDK` should target parity with the real opencode app client in `.local/opencode/packages/app`, not the full server or TUI control surface.

Scope:
- Track parity against the app client route usage documented in `docs/opencode-swift-client-parity.md`.
- Coordinate the child Beans `capi`, `cboo`, `cses`, `ctrn`, `cfil`, `cset`, `cadv`, and `ctst`.
- Exclude TUI-only routes, `app.log`, and PTY terminal parity unless the product scope expands later.

Acceptance criteria:
- The Swift client can perform the same bootstrap, session, transcript, permissions/questions, and file-context flows as the app client.
- Required validation passes for completed child Beans.
- The parity checklist stays aligned with actual app client usage, not the full server contract.
