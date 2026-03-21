---
# opencode-pocket-sdktoolm
title: P1 split ToolModels into command, LSP, formatter, and MCP files
status: completed
type: task
priority: medium
tags:
    - sdk
    - refactor
    - models
    - tools
created_at: 2026-03-21T05:55:08Z
updated_at: 2026-03-21T06:06:49Z
---

`ToolModels.swift` currently mixes several unrelated domains and has become difficult to scan.

Scope:
- Split command, LSP, formatter, and MCP models into separate files.
- Keep the existing types and names intact.
- Limit changes to file organization only.

Acceptance criteria:
- Tool-related models are grouped by concern in smaller files.
- No public type names or behavior change.
- Validation passes before completion.
