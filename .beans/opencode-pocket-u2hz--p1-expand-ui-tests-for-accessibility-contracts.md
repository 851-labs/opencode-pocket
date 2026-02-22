---
# opencode-pocket-u2hz
title: P1 expand UI tests for accessibility identifier contracts
status: completed
type: task
priority: normal
tags:
    - testing
    - ui-tests
    - accessibility
    - contract
created_at: 2026-02-22T02:17:54Z
updated_at: 2026-02-22T02:40:32Z
---

AGENTS requires stable accessibility/test contracts (`composer.*`, `drawer.*`, `workspace.*`, `message.*`), but current UI tests only lightly cover these surfaces.

Scope:
- Add focused UI tests that assert key identifiers exist and remain functional across primary flows.
- Cover at least workspace bootstrap, drawer/session selection, composer actions, and message copy affordances.
- Keep tests resilient to timing by using existing mock/testing launch modes.

Acceptance criteria:
- Contract-level UI tests fail if required identifiers are removed or renamed.
- New tests pass on CI/local simulator runs.
- Existing UI test behavior remains stable.
