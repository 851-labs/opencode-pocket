---
# opencode-pocket-capi
title: P0 document app-driven Swift client parity scope
status: completed
type: task
priority: high
tags:
    - sdk
    - client
    - parity
    - docs
created_at: 2026-03-20T21:50:45Z
updated_at: 2026-03-20T21:52:10Z
---

We need a stable source of truth for Swift client parity that follows the real opencode app client instead of every server route.

Scope:
- Audit server API usage in `.local/opencode/packages/app`.
- Document the must-have, phase-2, and out-of-scope route families for Swift parity.
- Link the route checklist to concrete app-client reference files.

Acceptance criteria:
- A parity checklist exists in repo and clearly separates core parity from optional follow-up work.
- The checklist names the reference app files that justify the scope.
- The Bean is completed with a commit so later implementation can follow the narrowed target.
