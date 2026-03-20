---
# opencode-pocket-cboo
title: P0 add client bootstrap and global sync parity to OpenCodeSDK
status: todo
type: feature
priority: high
tags:
    - sdk
    - client
    - bootstrap
    - events
created_at: 2026-03-20T21:50:45Z
updated_at: 2026-03-20T21:50:45Z
---

The Swift client needs the same startup and live-sync primitives used by the opencode app client.

Scope:
- Ensure `global.health`, `global.config.get`, `global.event`, and `path.get` are exposed with app-usable models.
- Align event subscription behavior with the app client's global sync flow.
- Add any bootstrap-oriented models needed for provider, project, and config hydration.

Acceptance criteria:
- The SDK can power the same connection bootstrap flow used by the app client.
- Global event streaming is suitable for app-side live sync.
- Required validation passes.
