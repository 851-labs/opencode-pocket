---
# opencode-pocket-spkg
title: P1 reorganize OpenCodeSDK into domain-based folders
status: completed
type: task
priority: high
tags:
    - sdk
    - package
    - structure
    - cleanup
created_at: 2026-03-21T05:24:26Z
updated_at: 2026-03-21T05:41:53Z
---

Now that the SDK has a single public module, the folder layout should match that public shape instead of preserving the old split module roots.

Scope:
- Move source files under `Sources/OpenCodeSDK` using domain-based folders for client, transport, and models.
- Move tests under `Tests/OpenCodeSDKTests` with folders that mirror concerns.
- Update package metadata, docs, and project generation for the new structure.

Acceptance criteria:
- The package layout matches the single-module `OpenCodeSDK` surface.
- Tests and docs point at the new paths.
- `swift test`, macOS build, and iOS simulator build pass.
