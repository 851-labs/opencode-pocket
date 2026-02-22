---
# opencode-pocket-k6jl
title: P2 move message normalization and parsing helpers into SDK layer
status: completed
type: task
priority: normal
tags:
    - architecture
    - sdk
    - networking
    - refactor
created_at: 2026-02-22T02:17:54Z
updated_at: 2026-02-22T05:03:30Z
---

AGENTS guidance says protocol/API behavior should live in `OpenCodeSDK`; app store code still performs some message parsing/normalization work that can be centralized.

Scope:
- Audit parsing/normalization logic in app stores that belongs to protocol concerns.
- Move that logic into `Packages/OpenCodeSDK` APIs/helpers with app-facing interfaces.
- Add or update SDK tests to protect behavior.

Acceptance criteria:
- App layer uses SDK interfaces instead of local protocol parsing internals.
- SDK tests cover extracted logic.
- App build/tests and SDK tests pass.
