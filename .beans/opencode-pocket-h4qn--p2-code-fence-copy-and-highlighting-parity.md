---
# opencode-pocket-h4qn
title: P2 code fence copy and highlighting parity
status: todo
type: task
priority: normal
tags:
    - markdown
    - code-block
    - ux
    - parity
created_at: 2026-02-22T21:08:24Z
updated_at: 2026-02-22T21:08:24Z
---

Restore polished code-block UX after the Textual migration.

Scope:
- Implement transcript code fence chrome (language label, copy action feedback).
- Reintroduce syntax highlighting behavior with a maintainable approach that works in both app platforms.
- Ensure code block scrolling, selection, and copy semantics remain reliable.

Acceptance criteria:
- Code fences are clearly differentiated from prose and include copy affordances.
- Copy action works on iOS and macOS.
- Required validation passes (macOS build, iOS tests).
