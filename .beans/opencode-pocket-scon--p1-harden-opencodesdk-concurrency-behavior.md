---
# opencode-pocket-scon
title: P1 harden OpenCodeSDK concurrency behavior
status: in_progress
type: feature
priority: high
tags:
    - sdk
    - concurrency
    - swift-6
    - networking
created_at: 2026-03-21T00:21:54Z
updated_at: 2026-03-21T00:26:57Z
---

The Swift concurrency review surfaced two real SDK issues in the networking layer: long-lived SSE processing can inherit caller actor isolation, and JSON decoding currently runs on the caller's actor under Swift 6.2 semantics.

Scope:
- Coordinate the child Beans `ssei`, `deca`, and `cgrs`.
- Keep this follow-up tightly scoped to genuine concurrency correctness and behavior issues in `OpenCodeSDK`.
- Avoid broad networking refactors that are unrelated to the reviewed concurrency risks.

Acceptance criteria:
- SSE processing no longer depends on the subscriber's actor isolation.
- Response decoding is explicitly offloaded from the caller actor where needed.
- Targeted regression coverage exists for the changed concurrency behavior.
- Required validation passes before completion.
