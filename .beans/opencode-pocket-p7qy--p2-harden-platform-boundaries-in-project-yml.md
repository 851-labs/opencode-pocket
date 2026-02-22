---
# opencode-pocket-p7qy
title: P2 harden iOS and macOS source boundaries in project.yml
status: completed
type: task
priority: normal
tags:
    - xcodegen
    - platform
    - project-config
    - swiftui
created_at: 2026-02-22T02:17:54Z
updated_at: 2026-02-22T02:37:53Z
---

The app now has split workspace directories (`Features/Workspace` and `Features/MacWorkspace`), but platform exclusions in `project.yml` still only list top-level files.

Scope:
- Update `EXCLUDED_SOURCE_FILE_NAMES[...]` patterns to exclude full platform-specific directory groups where appropriate.
- Keep `#if os(...)` guards where useful, but rely on project-level boundaries as primary compile filter.
- Regenerate `OpenCodePocket.xcodeproj` with XcodeGen.

Acceptance criteria:
- iOS and macOS builds include only intended platform files by configuration.
- Project regenerates cleanly from `project.yml`.
- No behavior regressions in workspace features.
