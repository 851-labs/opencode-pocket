---
# opencode-pocket-d3fw
title: P2 add TranscriptUI preview fixtures
status: todo
type: task
priority: normal
tags:
    - previews
    - markdown
    - transcript
    - developer-experience
created_at: 2026-02-22T21:08:24Z
updated_at: 2026-02-22T21:08:24Z
---

Add a preview catalog to make markdown rendering regressions visible during development.

Scope:
- Create reusable fixture content for common and edge-case markdown structures.
- Add SwiftUI previews covering paragraphs, nested lists, links, blockquotes, tables, code fences, and mixed content.
- Include preview cases for both transcript body styles and reasoning disclosure content.

Acceptance criteria:
- Developers can verify rendering parity quickly in previews without running the full app.
- Fixtures are easy to extend for future markdown bugs.
- Required validation passes (macOS build, iOS tests).
