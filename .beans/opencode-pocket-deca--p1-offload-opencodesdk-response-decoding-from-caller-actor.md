---
# opencode-pocket-deca
title: P1 offload OpenCodeSDK response decoding from the caller actor
status: todo
type: task
priority: high
tags:
    - sdk
    - concurrency
    - decoding
    - swift-6
created_at: 2026-03-21T00:21:54Z
updated_at: 2026-03-21T00:21:54Z
---

Under Swift 6.2, plain async helper calls stay on the caller's actor by default. `OpenCodeClient` currently decodes response payloads inline, which can keep large JSON decoding work on `MainActor` for UI callers.

Scope:
- Introduce an explicit off-actor decode path for standard and paged SDK responses.
- Preserve the current error mapping and public API surface.
- Limit changes to real decode hot paths rather than speculative optimization.

Acceptance criteria:
- Response decoding used by the SDK no longer depends on caller actor isolation.
- Standard and paged request paths retain current behavior and error handling.
- Required validation passes before completion.
