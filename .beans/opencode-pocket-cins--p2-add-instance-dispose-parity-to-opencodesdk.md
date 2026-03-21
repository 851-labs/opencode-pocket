---
# opencode-pocket-cins
title: P2 add instance dispose parity to OpenCodeSDK
status: completed
type: task
priority: medium
tags:
    - sdk
    - client
    - cleanup
    - instance
created_at: 2026-03-20T23:21:08Z
updated_at: 2026-03-21T00:02:04Z
---

The app client uses instance cleanup when tearing down directory-scoped state, but `OpenCodeSDK` does not yet expose that route.

Scope:
- Add a Swift wrapper for `instance.dispose`.
- Keep the API explicit about directory-scoped cleanup semantics.
- Add tests that verify the request path and success handling.

Acceptance criteria:
- The Swift client can dispose of an instance through the SDK.
- Instance cleanup has automated request coverage.
- Required validation passes before the Bean is completed.
