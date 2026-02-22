---
# opencode-pocket-s4rw
title: P1 add security regression tests for credential handling
status: completed
type: task
priority: normal
tags:
    - security
    - testing
    - keychain
    - storage
created_at: 2026-02-22T02:17:54Z
updated_at: 2026-02-22T02:47:30Z
---

AGENTS emphasizes credential safety (no plaintext logging, Keychain-backed password storage), but there is no explicit regression test suite that locks this behavior.

Scope:
- Add tests around `ConnectionStorage` and `ConnectionStore` to verify password persistence/deletion paths.
- Assert plaintext secrets are not written to non-Keychain settings payloads.
- Add guard tests for connection persistence edge cases (username/baseURL changes, delete behavior).

Acceptance criteria:
- Security tests fail if password handling regresses from Keychain-backed behavior.
- Tests cover save/load/delete credential lifecycle.
- Test suite passes on default local setup.
