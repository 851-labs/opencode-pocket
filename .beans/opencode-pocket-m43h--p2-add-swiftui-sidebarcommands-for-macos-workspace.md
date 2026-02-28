---
# opencode-pocket-m43h
title: P2 add SwiftUI SidebarCommands for macOS workspace
status: todo
type: feature
priority: normal
tags:
    - macos
    - swiftui
    - sidebar
    - commands
    - keyboard-shortcuts
created_at: 2026-02-28T01:53:12Z
updated_at: 2026-02-28T01:53:12Z
---

Add standard SwiftUI SidebarCommands on macOS so users can toggle the workspace sidebar from the menu and keyboard shortcut.

Scope:
- Add macOS-only `.commands { SidebarCommands() }` wiring in `OpenCodePocketApp`.
- Keep iOS behavior unchanged.
- Ensure the command works with existing `NavigationSplitView` sidebar behavior.

Acceptance criteria:
- macOS app exposes Sidebar command(s) and toggles sidebar visibility in workspace windows.
- iOS remains unaffected.
- Required validation passes:
  - `xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination "platform=macOS" build`
  - `xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination "platform=iOS Simulator,name=iPhone 17,OS=26.2" build`
  - `swift test` in `Packages/OpenCodeSDK`
