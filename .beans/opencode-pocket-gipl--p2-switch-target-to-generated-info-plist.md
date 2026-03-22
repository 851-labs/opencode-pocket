---
# opencode-pocket-gipl
title: P2 switch target to generated Info.plist
status: completed
type: chore
priority: medium
tags:
    - app
    - xcodegen
    - build
created_at: 2026-03-22T05:21:00Z
updated_at: 2026-03-22T05:22:28Z
---

Switch the app target from a file-backed Info.plist to Xcode/XcodeGen-generated Info.plist settings.

Scope:
- Remove explicit file-based Info.plist wiring from the XcodeGen manifest.
- Enable generated Info.plist output for the app target.
- Preserve required bundle and launch-screen properties.
- Regenerate the project and verify macOS and iOS builds plus SDK tests.

Acceptance criteria:
- The app target no longer references `OpenCodePocket/Support/Info.plist` as `INFOPLIST_FILE`.
- Required Info.plist properties are supplied by generated configuration.
- macOS build, iOS simulator build, and `swift test` succeed.
