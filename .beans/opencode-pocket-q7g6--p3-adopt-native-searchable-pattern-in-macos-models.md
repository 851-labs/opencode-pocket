---
# opencode-pocket-q7g6
title: P3 adopt native searchable pattern in macOS Models settings tab
status: completed
type: task
priority: low
tags:
    - swiftui
    - ui-patterns
    - settings
    - search
created_at: 2026-02-21T23:02:39Z
updated_at: 2026-02-21T23:09:45Z
---

Adopt the SwiftUI searchable component pattern in the macOS Models settings tab.

Scope:
- Replace custom search TextField in `MacSettingsModelsTab` with `.searchable` on the list/scroll container.
- Preserve existing filtering semantics (provider + model name/id matches).
- Keep keyboard and accessibility behavior aligned with native searchable expectations.

Acceptance criteria:
- Models tab uses native `.searchable` API.
- Filter results match current behavior.
- macOS build and iOS tests pass.
