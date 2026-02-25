---
# opencode-pocket-w1mq
title: P1 refactor macOS workspace shell into FeaturesV2 split files
status: completed
type: task
priority: high
tags:
    - refactor
    - swiftui
    - macos
    - navigation
    - previews
created_at: 2026-02-25T12:00:00Z
updated_at: 2026-02-25T14:35:00Z
---

Move macOS workspace shell and NavigationSplit orchestration code from `OpenCodePocket/Features/MacWorkspaceView.swift` into focused `FeaturesV2` files, while keeping existing reusable components under `OpenCodePocket/Features/MacWorkspace` unchanged.

Scope:
- Extract shell/sidebar/detail/bootstrap/session-actions composition to `OpenCodePocket/FeaturesV2/Workspace/MacWorkspace/*`.
- Keep transcript/composer/card component files in `OpenCodePocket/Features/MacWorkspace/*` for now.
- Replace `onTapGesture`-driven sidebar selection with semantic List/Button interaction patterns.
- Add granular workspace shell previews using a seeded preview dependency graph.

Acceptance criteria:
- `MacWorkspaceView` remains the app entry point but delegates shell logic to FeaturesV2.
- Sidebar selection no longer relies on row tap gestures.
- New workspace shell previews compile and run with deterministic seeded data.
- iOS/macOS project source exclusions remain correct.
- Required validation passes (macOS build, iOS simulator build, OpenCodeSDK tests).
