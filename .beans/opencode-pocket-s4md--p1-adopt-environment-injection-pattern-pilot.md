---
# opencode-pocket-s4md
title: P1 adopt environment injection pattern pilot
status: completed
type: refactor
priority: high
tags:
    - architecture
    - swiftui
    - dependency-injection
    - settings
created_at: 2026-02-25T05:38:50Z
updated_at: 2026-02-25T05:42:44Z
---

Adopt an IceCubes-style environment injection pattern for app-wide stores, piloting the change in root app wiring and the V2 macOS settings subtree.

Scope:
- Add a root dependency injection helper for `ConnectionStore` and `WorkspaceStore`.
- Inject stores at scene roots in `OpenCodePocketApp`.
- Convert `RootView` to read stores from `@Environment`.
- Convert `MacSettingsView`, `MacSettingsGeneralTab`, and `MacSettingsModelsTab` to read `WorkspaceStore` from `@Environment`.
- Update settings previews to inject the preview store via environment.

Acceptance criteria:
- Main app and Settings scene compile with environment-injected stores.
- V2 macOS settings no longer require explicit `store` init parameters.
- Existing behavior remains unchanged.
- macOS build and iOS tests pass.
