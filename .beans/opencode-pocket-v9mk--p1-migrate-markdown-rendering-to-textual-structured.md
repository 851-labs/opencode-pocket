---
# opencode-pocket-v9mk
title: P1 migrate markdown rendering to Textual StructuredText
status: completed
type: task
priority: high
tags:
    - markdown
    - textual
    - transcript
    - parity
created_at: 2026-02-22T21:08:24Z
updated_at: 2026-02-22T21:31:00Z
---

Replace the current `AttributedString(markdown:)` prose pipeline with Textual so block structure (lists, paragraph spacing, headings, blockquotes) is preserved.

Scope:
- Add Textual dependency to `TranscriptUI`.
- Implement `TranscriptMarkdownView` using `StructuredText` for block markdown.
- Migrate transcript and tool-output surfaces currently using `RichMarkdownText` to the new view.
- Preserve text selection and external link behavior.

Acceptance criteria:
- Bullet and numbered lists render as list items (not collapsed prose).
- iOS and macOS transcript cards render block markdown consistently.
- Required validation passes (SDK tests if touched, macOS build, iOS tests).
