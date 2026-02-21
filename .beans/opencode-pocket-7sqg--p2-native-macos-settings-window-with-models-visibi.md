---
# opencode-pocket-7sqg
title: P2 native macOS settings window with models visibility controls
status: completed
type: task
priority: normal
tags:
    - parity
    - macos
    - settings
    - models
    - ux
created_at: 2026-02-21T18:42:08Z
updated_at: 2026-02-21T19:11:15Z
---

Add a native macOS settings window with a Models tab that lets users toggle which models appear in the composer, following OpenCode desktop patterns.

Scope:
- Add a macOS settings entry point from the app UI and present a native settings window/sheet experience.
- Build tabbed settings navigation with an initial Models tab (future-friendly for more tabs).
- Models tab UX parity direction from OpenCode desktop:
  - searchable model list,
  - grouped by provider,
  - per-model visibility switch.
- Persist model visibility preferences locally and apply them when deriving composer model menus.
- Ensure hidden models do not appear in iOS/macOS composer model pickers, while preserving selected-model fallback behavior.

Acceptance criteria:
- macOS app exposes Settings and opens a native settings surface.
- Models tab renders provider-grouped model rows with toggle controls and search.
- Visibility toggles immediately affect composer model picker options.
- Visibility choices persist across relaunch/reconnect.
- Existing model selection remains valid or gracefully falls back when hidden.
- macOS build + iOS tests pass.
