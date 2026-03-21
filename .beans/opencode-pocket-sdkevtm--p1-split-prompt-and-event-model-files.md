---
# opencode-pocket-sdkevtm
title: P1 split prompt and event model files
status: completed
type: task
priority: medium
tags:
    - sdk
    - refactor
    - models
    - events
created_at: 2026-03-21T05:55:08Z
updated_at: 2026-03-21T06:06:49Z
---

`PromptAndEventModels.swift` contains both prompt payloads and event types, which makes the file larger and less focused than it needs to be.

Scope:
- Split prompt-related types and event-related types into separate files.
- Preserve existing public names and behavior.
- Keep the refactor mechanical and low-risk.

Acceptance criteria:
- Prompt and event models live in separate focused files.
- Existing APIs and tests continue to work unchanged.
- Validation passes before completion.
