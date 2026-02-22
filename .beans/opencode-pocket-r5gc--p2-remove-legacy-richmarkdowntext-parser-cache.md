---
# opencode-pocket-r5gc
title: P2 remove legacy RichMarkdownText parser cache
status: todo
type: task
priority: normal
tags:
    - cleanup
    - markdown
    - technical-debt
created_at: 2026-02-22T21:08:24Z
updated_at: 2026-02-22T21:08:24Z
---

Clean up old markdown parsing/rendering internals once Textual-backed transcript rendering is in place.

Scope:
- Remove obsolete `RichMarkdownText` parsing/cache/linkification/highlighting helpers replaced by `TranscriptUI`.
- Keep compatibility shims only where needed to avoid broad churn.
- Ensure no duplicate markdown rendering stacks remain in app code.

Acceptance criteria:
- Transcript markdown has one clear rendering path.
- Dead code is removed and project compiles without warnings introduced by cleanup.
- Required validation passes (macOS build, iOS tests).
