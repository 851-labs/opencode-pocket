---
# opencode-pocket-t9nb
title: P2 split WorkspaceStore into domain-focused files with extensions
status: completed
type: task
priority: normal
tags:
    - architecture
    - refactor
    - app-store
    - swift
created_at: 2026-02-22T02:17:54Z
updated_at: 2026-02-22T07:57:00Z
---

`WorkspaceStore.swift` is currently a large monolith (~1.3k lines), which makes architecture boundaries harder to maintain even though AGENTS favors focused ownership.

Scope:
- Split `WorkspaceStore` into feature-oriented files (e.g. sessions, transcript stream handling, prompts, composer actions, settings/models).
- Keep one observable type and current external API behavior intact.
- Preserve side-effect ownership in store methods and avoid view-level leakage.

Acceptance criteria:
- Store functionality is equivalent before/after refactor.
- No single store extension file is monolithic.
- macOS build and iOS tests pass after refactor.
