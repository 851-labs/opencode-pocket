---
# opencode-pocket-n8yb
title: P1 add markdown regression UI test coverage
status: completed
type: task
priority: high
tags:
    - tests
    - ui-tests
    - markdown
    - parity
created_at: 2026-02-22T21:08:24Z
updated_at: 2026-02-22T21:52:00Z
---

Add stable UI regression coverage for markdown transcript rendering so list and spacing regressions are caught early.

Scope:
- Add deterministic markdown fixture messages in workspace mock mode for UI tests.
- Extend UI tests to verify transcript contracts for markdown content (lists, headings, code snippets, links visibility).
- Keep accessibility identifiers stable and update tests in the same change when identifiers evolve.

Acceptance criteria:
- New tests fail against broken markdown rendering and pass with the Textual-based renderer.
- Existing UI tests remain green.
- Required validation passes (macOS build, iOS tests).
