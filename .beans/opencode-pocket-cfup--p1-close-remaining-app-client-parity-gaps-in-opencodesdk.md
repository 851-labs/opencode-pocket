---
# opencode-pocket-cfup
title: P1 close remaining app-client parity gaps in OpenCodeSDK
status: in_progress
type: feature
priority: high
tags:
    - sdk
    - client
    - parity
    - follow-up
created_at: 2026-03-20T23:21:08Z
updated_at: 2026-03-21T00:00:28Z
---

The main Swift client parity track is complete, but a small follow-up set of app-used APIs still remains outside `OpenCodeSDK`.

Scope:
- Coordinate the child Beans `ccmd`, `cmcp`, `cins`, and optional `cpty`.
- Keep the follow-up focused on APIs used by `.local/opencode/packages/app` rather than widening back out to full server-surface parity.
- Treat PTY cleanup as explicitly optional unless terminal parity is brought back into scope.

Acceptance criteria:
- Required follow-up Beans are completed and validated.
- `command.list`, MCP connect/disconnect, and instance dispose are covered by the Swift SDK.
- `cpty` is either completed or intentionally deferred with the scope decision preserved in the Bean state.
