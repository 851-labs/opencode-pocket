---
# opencode-pocket-ssup
title: P2 add skill and formatter status parity to OpenCodeSDK
status: todo
type: feature
priority: medium
tags:
    - sdk
    - parity
    - skills
    - formatter
created_at: 2026-03-21T04:48:08Z
updated_at: 2026-03-21T04:48:08Z
---

The OpenAPI surface exposes skill discovery and formatter status endpoints that are useful to SDK consumers, but currently missing from `OpenCodeSDK`.

Scope:
- Add `app.skills` and `formatter.status` wrappers to `OpenCodeClient`.
- Introduce small typed models for skills and formatter status entries.
- Keep these endpoints as lightweight metadata/status APIs without adding extra abstraction.

Acceptance criteria:
- The SDK can list available skills and formatter status through typed Swift APIs.
- The new routes have request and decode coverage in Swift Testing.
- Required validation passes before completion.
