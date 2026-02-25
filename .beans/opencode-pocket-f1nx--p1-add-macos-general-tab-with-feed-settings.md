---
# opencode-pocket-f1nx
title: P1 add macOS General tab with Feed settings
status: completed
type: task
priority: high
tags:
    - macos
    - settings
    - ui
    - parity
created_at: 2026-02-25T00:09:07Z
updated_at: 2026-02-25T00:28:05Z
---

Add a native macOS `General` settings tab and move feed-related toggles there to match OpenCode desktop structure.

Scope:
- Add `General` tab alongside `Models` in `MacSettingsView`.
- In `General`, add a `Feed` section using `Form`, `Section`, and `LabeledContent` rows.
- Add switch rows for:
  - Show reasoning summaries
  - Expand shell tool parts
  - Expand edit tool parts
- Keep control styling native macOS (`.toggleStyle(.switch)`).

Acceptance criteria:
- Settings shows `General` and `Models` tabs.
- `General` contains a `Feed` section with the three feed toggles.
- macOS build and iOS tests pass.
