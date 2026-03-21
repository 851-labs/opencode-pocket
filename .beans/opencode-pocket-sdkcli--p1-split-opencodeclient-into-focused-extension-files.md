---
# opencode-pocket-sdkcli
title: P1 split OpenCodeClient into focused extension files
status: completed
type: task
priority: high
tags:
    - sdk
    - refactor
    - client
    - structure
created_at: 2026-03-21T05:55:08Z
updated_at: 2026-03-21T06:06:49Z
---

`OpenCodeClient.swift` has grown beyond a thousand lines and now mixes route families, event streaming, and request plumbing in one file.

Scope:
- Keep one `OpenCodeClient` type, but move methods into extension files grouped by concern.
- Separate route families from shared request machinery and event-stream handling.
- Preserve all existing APIs and behavior.

Acceptance criteria:
- `OpenCodeClient` is split into smaller files that are easier to navigate.
- The public API surface remains unchanged.
- Validation passes before completion.
