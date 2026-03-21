---
# opencode-pocket-cgrs
title: P2 add concurrency regression coverage for OpenCodeSDK networking
status: completed
type: task
priority: medium
tags:
    - sdk
    - concurrency
    - testing
    - regression
created_at: 2026-03-21T00:21:54Z
updated_at: 2026-03-21T00:29:34Z
---

Changing SSE execution context and response decoding behavior should be protected by focused concurrency regression tests.

Scope:
- Add targeted tests for SSE cancellation and termination behavior after the producer isolation change.
- Add focused coverage for the off-actor decode path if the implementation changes materially.
- Avoid timing-based or brittle executor-specific tests.

Acceptance criteria:
- The changed concurrency behavior is covered by stable automated tests.
- Tests follow Swift Testing async patterns without sleep-based synchronization.
- Required validation passes before completion.
