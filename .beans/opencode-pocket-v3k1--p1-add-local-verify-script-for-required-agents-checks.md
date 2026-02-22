---
# opencode-pocket-v3k1
title: P1 add local verify script for required AGENTS checks
status: cancelled
type: task
priority: normal
tags:
    - workflow
    - validation
    - ci
    - tooling
created_at: 2026-02-22T02:17:54Z
updated_at: 2026-02-22T02:34:17Z
---

AGENTS requires consistent validation (macOS build, iOS tests, and SDK tests when SDK changes), but the repo has no single local command that codifies this contract.

Scope:
- Add a local script (`scripts/verify.sh`) that runs required checks in the right order.
- Include path-aware behavior so SDK tests run automatically when files under `Packages/OpenCodeSDK` changed.
- Document script usage in `README.md` or equivalent contributor docs.

Acceptance criteria:
- One command executes AGENTS-required validation for app-only changes.
- SDK changes trigger `swift test` in `Packages/OpenCodeSDK`.
- Script exits non-zero on any failed step and prints clear step-level status.
