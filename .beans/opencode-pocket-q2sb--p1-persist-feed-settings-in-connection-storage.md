---
# opencode-pocket-q2sb
title: P1 persist feed settings in connection storage
status: completed
type: task
priority: high
tags:
    - settings
    - persistence
    - storage
    - parity
created_at: 2026-02-25T00:09:07Z
updated_at: 2026-02-25T00:37:27Z
---

Persist feed behavior settings so they survive reconnect/relaunch and stay in sync with desktop expectations.

Scope:
- Extend `ConnectionSettings` with:
  - `showReasoningSummaries`
  - `expandShellToolParts`
  - `expandEditToolParts`
- Wire initial values from `ConnectionStore` into `WorkspaceStore`.
- Persist updates via existing settings persistence flow.
- Ensure backwards-compatible decoding for older saved payloads (missing fields use defaults).

Acceptance criteria:
- Feed setting values persist across app relaunch.
- Existing users with old settings payloads keep sane defaults.
- No credential/security regressions in settings persistence.
