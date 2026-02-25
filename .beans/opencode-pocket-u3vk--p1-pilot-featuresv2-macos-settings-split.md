---
# opencode-pocket-u3vk
title: P1 pilot FeaturesV2 macOS settings split
status: completed
type: refactor
priority: high
tags:
    - architecture
    - settings
    - macos
    - featuresv2
created_at: 2026-02-25T04:37:00Z
updated_at: 2026-02-25T04:40:14Z
---

Pilot a FeaturesV2 migration by moving macOS settings UI into a dedicated `FeaturesV2/Settings/MacSettings` folder and splitting tab content into separate files.

Scope:
- Move settings root view into `FeaturesV2/Settings/MacSettings`.
- Split General and Models tabs into dedicated files.
- Remove the old monolithic `MacWorkspaceSettings.swift` file.
- Keep app wiring using `MacSettingsView` unchanged.
- Update project exclusions for the new macOS-only path.

Acceptance criteria:
- macOS settings compile from the new FeaturesV2 folder.
- Each settings tab has its own file.
- iOS target excludes the new macOS-only settings folder.
- macOS build and iOS tests pass.
