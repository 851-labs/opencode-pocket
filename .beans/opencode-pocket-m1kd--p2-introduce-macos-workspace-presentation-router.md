---
# opencode-pocket-m1kd
title: P2 introduce macOS workspace presentation router
status: completed
type: refactor
priority: medium
tags:
  - macos
  - workspace
  - routing
  - presentation
created_at: 2026-02-26T15:15:00Z
updated_at: 2026-02-26T15:15:00Z
---

Introduce a workspace-scoped presentation router for macOS so sheet/dialog/file-import state is centralized in one environment object and can be triggered from nested views without callback plumbing.

Scope:
- Add a typed macOS workspace router path with sheet destination, file importer state, and delete confirmation state.
- Inject router path into the workspace shell environment.
- Update sidebar to trigger rename/delete/add-project presentation via router environment.
- Keep business actions (archive/pin/select) in store or shell callbacks.

Validation:
- `xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination 'platform=macOS' build`
- `xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build`
- `swift test` in `Packages/OpenCodeSDK`
