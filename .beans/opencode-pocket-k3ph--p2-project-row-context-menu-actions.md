---
# opencode-pocket-k3ph
title: P2 add project row context menu actions on macOS
status: completed
type: feature
priority: medium
tags:
  - macos
  - sidebar
  - projects
  - context-menu
created_at: 2026-02-26T16:00:00Z
updated_at: 2026-02-26T16:00:00Z
---

Add right-click context menu actions on project rows in the macOS workspace sidebar.

Scope:
- Add project row context menu with New Session, Rename, and Remove.
- Add rename project sheet destination and sheet implementation.
- Add remove project confirmation dialog and remove-project store behavior.
- Add store APIs for rename/remove project and create session in a specific project.

Validation:
- `xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination 'platform=macOS' build`
- `xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build`
- `swift test` in `Packages/OpenCodeSDK`
