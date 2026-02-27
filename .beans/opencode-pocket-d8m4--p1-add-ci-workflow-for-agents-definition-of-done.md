---
# opencode-pocket-d8m4
title: P1 add CI workflow for AGENTS definition-of-done checks
status: scrapped
type: task
priority: normal
tags:
    - workflow
    - ci
    - testing
    - automation
created_at: 2026-02-22T02:17:54Z
updated_at: 2026-02-27T05:22:58Z
---

AGENTS defines required validation, but the repository currently has no GitHub Actions workflow to enforce those checks on pull requests.

Scope:
- Add `.github/workflows/ci.yml` to run macOS build and iOS test suite.
- Run SDK package tests in CI (always or conditionally based on changed paths).
- Surface failures as required PR checks.

Acceptance criteria:
- A PR to `main` triggers CI automatically.
- Workflow runs macOS build + iOS tests successfully on healthy branches.
- SDK test coverage is included for SDK-touching changes.
