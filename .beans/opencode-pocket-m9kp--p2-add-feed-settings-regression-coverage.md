---
# opencode-pocket-m9kp
title: P2 add Feed settings regression coverage
status: completed
type: task
priority: normal
tags:
    - tests
    - settings
    - regression
    - parity
created_at: 2026-02-25T00:09:07Z
updated_at: 2026-02-25T00:55:24Z
---

Add regression tests to lock feed settings persistence and behavior parity.

Scope:
- Add unit coverage for settings encode/decode defaults and persistence for new feed flags.
- Add/extend UI contract tests for settings surface visibility and reasoning toggle behavior.
- Add focused transcript behavior checks for feed toggle effects where feasible.

Acceptance criteria:
- New feed settings are covered by automated tests.
- Test suite catches regressions in persistence and reasoning visibility behavior.
- macOS build and iOS tests pass.
