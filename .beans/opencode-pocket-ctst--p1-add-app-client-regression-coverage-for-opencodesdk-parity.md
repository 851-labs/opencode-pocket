---
# opencode-pocket-ctst
title: P1 add app-client regression coverage for OpenCodeSDK parity
status: todo
type: task
priority: high
tags:
    - sdk
    - client
    - testing
    - parity
created_at: 2026-03-20T21:50:45Z
updated_at: 2026-03-20T21:50:45Z
---

Parity work will drift unless the SDK test suite protects the route families the app client actually relies on.

Scope:
- Add or extend tests for bootstrap, session core, transcript support, file-context, and settings/auth flows.
- Prefer fixtures and focused client tests over broad server-surface auditing.
- Keep required validation tied to macOS build, iOS simulator build, and `swift test` in `Packages/OpenCodeSDK`.

Acceptance criteria:
- The SDK test suite covers the app-driven parity surface.
- Future drift against the app client's route usage is easier to detect.
- Required validation passes.
