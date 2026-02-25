---
# opencode-pocket-n3r8
title: P1 remove app test targets and keep tests in OpenCodeSDK only
status: completed
type: chore
priority: high
tags:
  - testing
  - xcodegen
  - sdk
created_at: 2026-02-25T19:44:19Z
updated_at: 2026-02-25T19:50:06Z
---

Remove `OpenCodePocketTests` and `OpenCodePocketUITests` targets from the app project and keep automated tests in `Packages/OpenCodeSDK`.

Scope:
- Remove app unit/UI test targets from `project.yml` and regenerate project files.
- Delete app test directories.
- Move SDK-relevant tests into package tests where appropriate.
- Update testing docs to reflect SDK-only test execution.

Acceptance criteria:
- Xcode project no longer contains app test targets.
- No `OpenCodePocketTests` or `OpenCodePocketUITests` directories remain.
- SDK tests continue to pass via `swift test`.
- App build validations pass.
