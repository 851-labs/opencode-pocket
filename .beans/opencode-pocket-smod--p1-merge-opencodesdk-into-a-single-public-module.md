---
# opencode-pocket-smod
title: P1 merge OpenCodeSDK into a single public module
status: completed
type: feature
priority: high
tags:
    - sdk
    - package
    - modules
    - migration
created_at: 2026-03-21T05:19:16Z
updated_at: 2026-03-21T05:22:29Z
---

The SDK should present a single public module and product, `OpenCodeSDK`, instead of the split `OpenCodeModels` and `OpenCodeNetworking` products.

Scope:
- Collapse the package to a single public target and product while preserving internal folder organization.
- Update app and test imports to `import OpenCodeSDK`.
- Regenerate the Xcode project after updating `project.yml` and validate the workspace builds.

Acceptance criteria:
- The package exposes one public module/product named `OpenCodeSDK`.
- App code and tests build using `import OpenCodeSDK` only.
- `swift test`, macOS build, and iOS simulator build pass.
