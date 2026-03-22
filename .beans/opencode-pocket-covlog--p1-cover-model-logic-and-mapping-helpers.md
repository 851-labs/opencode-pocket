---
# opencode-pocket-covlog
title: P1 cover model logic and mapping helpers
status: completed
type: task
priority: medium
tags:
    - sdk
    - testing
    - coverage
    - logic
created_at: 2026-03-22T05:39:31Z
updated_at: 2026-03-22T05:55:38Z
---

Several of the remaining under-covered files contain branchy mapping and helper logic that is more valuable than pure initializer coverage, especially around events, message parts, and tool execution state.

Scope:
- Add focused tests for:
  - `Models/Sessions/EventModels.swift`
  - `Models/Sessions/MessagePart.swift`
  - `Models/Sessions/MessageMetadata.swift`
  - `Models/Sessions/PromptModels.swift`
  - `Models/Tools/ToolExecutionModels.swift`
- Cover event-type mapping, helper properties, nested payload behavior, and message/tool state branches.

Acceptance criteria:
- Logic-heavy helper methods and branchy mapping code have direct tests.
- Tests remain deterministic and do not rely on unrelated client smoke coverage.
- Required validation passes before completion.
