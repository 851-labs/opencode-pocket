---
# opencode-pocket-covgat
title: P2 add a lightweight SDK coverage guardrail
status: completed
type: task
priority: medium
tags:
    - sdk
    - testing
    - coverage
    - tooling
created_at: 2026-03-22T05:39:31Z
updated_at: 2026-03-22T06:18:27Z
---

Now that coverage can be measured locally, the repo should have a lightweight way to keep it from regressing after the SDK reaches the desired target.

Scope:
- Build on `Packages/OpenCodeSDK/Scripts/coverage.sh` with a minimal guardrail such as a threshold check or a small script wrapper.
- Keep the solution simple and local-first; do not introduce heavy CI coupling unless needed.
- Document how the guardrail should be used when validating SDK changes.

Acceptance criteria:
- There is a lightweight, repeatable way to detect coverage regressions.
- The guardrail fits the current repo workflow and remains easy to maintain.
- Required validation passes before completion.
