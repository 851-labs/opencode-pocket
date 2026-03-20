---
# opencode-pocket-ccmd
title: P1 add command catalog parity to OpenCodeSDK
status: completed
type: feature
priority: high
tags:
    - sdk
    - client
    - commands
    - bootstrap
created_at: 2026-03-20T23:21:08Z
updated_at: 2026-03-20T23:58:41Z
---

The opencode app loads the command catalog during bootstrap, but `OpenCodeSDK` still lacks a public wrapper for `command.list`.

Scope:
- Add models for the server command catalog shape used by the app client.
- Expose a Swift wrapper for `command.list` on `OpenCodeClient`.
- Add request and decode coverage so bootstrap parity includes the command catalog.

Acceptance criteria:
- The Swift client can load the command catalog entirely through `OpenCodeSDK`.
- Command payload decoding is covered by tests.
- Required validation passes before the Bean is completed.
