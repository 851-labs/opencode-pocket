---
# opencode-pocket-p6zr
title: P2 add project symbol customization in macOS sidebar
status: completed
type: feature
priority: medium
tags:
  - macos
  - sidebar
  - projects
  - sf-symbols
  - customization
created_at: 2026-02-26T16:30:00Z
updated_at: 2026-02-27T16:55:00Z
---

Add a project-level customization flow so users can pick a custom SF Symbol for each project from the project row context menu.

Scope:
- Add a `Customize` action to the project row context menu.
- Add persisted optional project symbol data in connection settings.
- Add workspace store APIs to update/reset a project's symbol.
- Add a macOS customize-project sheet with symbol input and reset/save actions.
- Render the chosen symbol in project rows (fallback to default folder icon).
- Optionally align project symbol rendering in related project list surfaces.

Acceptance criteria:
- Right-clicking a project row shows `Customize`.
- Users can enter/select a valid SF Symbol and save it for that project.
- Custom symbol persists across app restart.
- Resetting customization returns the icon to the default folder symbol.

Validation:
- `xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination 'platform=macOS' build`
- `xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build`
- `swift test` in `Packages/OpenCodeSDK`
