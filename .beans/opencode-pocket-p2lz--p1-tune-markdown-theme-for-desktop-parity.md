---
# opencode-pocket-p2lz
title: P1 tune markdown theme for desktop parity
status: completed
type: task
priority: normal
tags:
    - markdown
    - styling
    - parity
    - ui
created_at: 2026-02-22T21:08:24Z
updated_at: 2026-02-22T21:35:00Z
---

Tune the Textual style stack so transcript typography and spacing align more closely with OpenCode desktop.

Scope:
- Define paragraph, list, heading, inline code, link, and blockquote styles in `TranscriptUI`.
- Match list marker spacing/indent and paragraph rhythm seen in desktop transcript screenshots.
- Keep styles platform-appropriate for iOS/macOS while sharing one core style definition.

Acceptance criteria:
- Visual regressions like missing list rhythm and cramped prose are resolved.
- Styles remain readable in both light and dark appearances.
- Required validation passes (macOS build, iOS tests).
