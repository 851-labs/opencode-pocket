---
# opencode-pocket-covcli
title: P1 close remaining client and helper coverage gaps
status: completed
type: task
priority: medium
tags:
    - sdk
    - testing
    - coverage
    - client
created_at: 2026-03-22T05:39:31Z
updated_at: 2026-03-22T06:09:41Z
---

Most `OpenCodeClient` route files already have high coverage, but a few remaining helper branches and edge cases still need direct tests to reach full measured coverage.

Scope:
- Use the latest `coverage.sh` report to close residual misses in:
  - `Client/OpenCodeClient+RequestCore.swift`
  - `Client/OpenCodeClient+Events.swift`
  - `Client/OpenCodeClient+Interactions.swift`
  - `Client/OpenCodeClient+Sessions.swift`
  - `Client/OpenCodeClient+Files.swift`
  - `Transport/HTTPRequestBuilder.swift`
- Focus on malformed headers, alternate error envelopes, optional-parameter omission paths, and remaining SSE edge cases.

Acceptance criteria:
- Remaining helper and client misses are eliminated with focused tests.
- Coverage reaches the final target without weakening code structure.
- Required validation passes before completion.
