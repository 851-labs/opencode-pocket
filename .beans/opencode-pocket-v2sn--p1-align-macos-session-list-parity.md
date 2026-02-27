---
# opencode-pocket-v2sn
title: P1 align macOS session list visibility and ordering with OpenCode parity
status: completed
type: bug
priority: high
tags:
    - macos
    - sidebar
    - sessions
    - parity
created_at: 2026-02-26T16:20:00Z
updated_at: 2026-02-27T16:48:00Z
---

Align Pocket macOS sidebar session visibility and ordering with OpenCode behavior observed against the same server/workspace.

Scope:
- Reproduce mismatch on `/Users/alexandru/repos/851-labs/851` and document current vs expected ordering.
- Align sidebar visibility rules with OpenCode session list semantics (root-only session handling and archived filtering parity).
- Align sort behavior with OpenCode ordering rules for recent sessions.
- Investigate empty default-titled sessions (`New session - <ISO>`) and implement parity behavior for when they should/should not be shown.
- Ensure pinned section behavior stays consistent after visibility/sort updates.

Acceptance criteria:
- Session rows shown in Pocket match OpenCode expectations for the same workspace (including empty/default-titled session treatment).
- Session order matches OpenCode ordering for the same dataset.
- No regressions in selection, pinning, archive/remove flows.

Validation:
- `xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination 'platform=macOS' build`
- `xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build`
- `swift test` in `Packages/OpenCodeSDK`
