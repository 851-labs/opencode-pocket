---
# opencode-pocket-sdkmsgm
title: P1 split message and session model files
status: completed
type: task
priority: medium
tags:
    - sdk
    - refactor
    - models
    - sessions
created_at: 2026-03-21T05:55:08Z
updated_at: 2026-03-21T06:06:49Z
---

`MessageModels.swift` and `SessionModels.swift` mix several concepts into large files that are becoming harder to maintain.

Scope:
- Split message envelope/metadata/failure/token models into separate files.
- Split session entities, request payloads, and status models into separate files.
- Preserve the current public API and decoding behavior.

Acceptance criteria:
- Message and session types are organized into smaller files by concern.
- Existing APIs and tests continue to work unchanged.
- Validation passes before completion.
