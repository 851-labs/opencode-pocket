---
# opencode-pocket-v4rd
title: P1 apply Feed settings to transcript behavior
status: completed
type: task
priority: high
tags:
    - transcript
    - settings
    - tools
    - parity
created_at: 2026-02-25T00:09:07Z
updated_at: 2026-02-25T00:49:36Z
---

Make the new feed settings control transcript rendering behavior with parity to OpenCode desktop.

Scope:
- Keep reasoning summaries behavior controlled by the same persisted setting used in timeline rendering.
- Apply `expandShellToolParts` to default disclosure/open state for shell/bash tool parts.
- Apply `expandEditToolParts` to default disclosure/open state for edit/write/apply_patch tool parts.
- Implement behavior in both iOS and macOS transcript tool card implementations.
- Ensure quick menu toggle and settings toggle stay synchronized for reasoning summaries.

Acceptance criteria:
- Changing each feed setting immediately affects transcript behavior.
- Shell and edit tool part expansion defaults match configured values.
- Parity behavior is consistent between iOS and macOS app surfaces.
