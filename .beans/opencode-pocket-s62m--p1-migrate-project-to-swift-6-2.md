---
# opencode-pocket-s62m
title: P1 migrate project to Swift 6.2
status: completed
type: feature
priority: high
tags:
    - app
    - sdk
    - swift-6
    - migration
    - tooling
created_at: 2026-03-22T04:26:44Z
updated_at: 2026-03-22T04:32:32Z
---

Move the app target and both Swift packages from Swift 5.10 to the Swift 6.2 toolchain while keeping the project buildable on macOS and iOS and preserving SDK test coverage.

Scope:
- Fix strict-concurrency issues that block the Swift 6 migration in app and package targets.
- Update XcodeGen and SwiftPM language/tooling declarations for Swift 6.2.
- Regenerate the Xcode project after manifest changes.
- Run the required validation and address any resulting build or test failures.

Acceptance criteria:
- `project.yml` and package manifests target Swift 6.2-compatible settings.
- The macOS app build succeeds.
- The iOS simulator app build succeeds.
- `swift test` succeeds in `Packages/OpenCodeSDK`.
