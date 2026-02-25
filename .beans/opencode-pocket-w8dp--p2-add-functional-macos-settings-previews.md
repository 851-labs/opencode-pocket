---
# opencode-pocket-w8dp
title: P2 add functional SwiftUI previews for macOS settings
status: completed
type: task
priority: normal
tags:
    - ui
    - settings
    - previews
    - macos
created_at: 2026-02-25T04:59:55Z
updated_at: 2026-02-25T05:03:51Z
---

Add functional SwiftUI previews for the new FeaturesV2 macOS settings views.

Scope:
- Add reusable preview store setup for macOS settings previews.
- Add previews for root settings view and each settings tab file.
- Keep previews interactive and seeded with mock data where useful.

Acceptance criteria:
- Previews compile for `MacSettingsView`, `MacSettingsGeneralTab`, and `MacSettingsModelsTab`.
- Models preview renders realistic rows without requiring a live server.
- macOS build and iOS tests pass.
