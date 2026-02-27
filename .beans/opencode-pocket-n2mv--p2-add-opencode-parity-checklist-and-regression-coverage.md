---
# opencode-pocket-n2mv
title: P2 add OpenCode parity checklist and regression coverage for core UI
status: scrapped
type: task
priority: normal
tags:
    - parity
    - docs
    - testing
    - swiftui
created_at: 2026-02-22T02:17:54Z
updated_at: 2026-02-27T05:23:11Z
---

AGENTS expects desktop parity for transcript/composer/tool rendering, but parity checks are currently implicit and easy to miss during future refactors.

Scope:
- Add a parity checklist document tied to concrete desktop reference paths.
- Add targeted regression tests for high-risk parity behaviors (transcript grouping, prompt cards, tool cards, copy metadata behavior).
- Link the checklist to the feature development workflow.

Acceptance criteria:
- Parity checklist exists in repo and is referenced in contributor workflow.
- Regression coverage protects core parity behaviors from silent drift.
- Tests pass on default local test command.
