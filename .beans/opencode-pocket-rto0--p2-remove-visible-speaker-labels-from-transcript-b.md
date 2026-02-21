---
# opencode-pocket-rto0
title: P2 remove visible speaker labels from transcript bubbles
status: completed
type: task
priority: low
tags:
    - parity
    - transcript
    - ui
    - accessibility
created_at: 2026-02-21T18:31:20Z
updated_at: 2026-02-21T18:49:56Z
---

Remove visible "You" / "Assistant" captions from transcript cards on iOS and macOS while preserving accessibility role context.

Acceptance criteria:
- No visible speaker labels in transcript bubbles.
- Accessibility still exposes message role context.
- macOS build and iOS tests pass.
