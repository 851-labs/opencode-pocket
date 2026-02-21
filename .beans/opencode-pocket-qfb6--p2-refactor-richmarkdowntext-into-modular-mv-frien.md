---
# opencode-pocket-qfb6
title: P2 refactor RichMarkdownText into modular MV-friendly view components
status: completed
type: task
priority: normal
tags:
    - refactor
    - swiftui
    - markdown
created_at: 2026-02-21T22:39:25Z
updated_at: 2026-02-21T22:51:55Z
---

Refactor `OpenCodePocket/Features/RichMarkdownText.swift` to improve ordering and decomposition while keeping markdown rendering behavior unchanged.

Scope:
- Split long file into clearer sections (core view, parsing/cache, prose, code block, platform clipboard helpers).
- Move heavy helper logic into marked private extensions or nested helper types with explicit responsibilities.
- Keep copy/linkify/syntax-highlighting behavior and public API stable.

Acceptance criteria:
- File organization follows ordering conventions and large-file guidance.
- No behavioral regressions in markdown rendering/copy/link handling.
- macOS build and iOS tests pass.
