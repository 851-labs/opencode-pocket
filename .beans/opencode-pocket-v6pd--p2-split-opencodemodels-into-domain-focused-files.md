---
# opencode-pocket-v6pd
title: P2 split OpenCodeModels into domain-focused files
status: completed
type: task
priority: normal
tags:
    - architecture
    - refactor
    - sdk
    - swift
created_at: 2026-02-28T07:41:41Z
updated_at: 2026-02-28T07:43:12Z
---

`OpenCodeModels.swift` is a large monolith and mixes unrelated model domains, which makes ownership and review harder.

Scope:
- Split `Packages/OpenCodeSDK/Sources/OpenCodeModels/OpenCodeModels.swift` into domain-focused files.
- Preserve public API, naming, behavior, and serialization semantics.
- Keep private helper visibility intact where needed.

Acceptance criteria:
- The monolith is replaced by focused model files in `OpenCodeModels`.
- No model renames or behavior changes are introduced.
- macOS build, iOS simulator build, and `swift test` in `Packages/OpenCodeSDK` pass.
