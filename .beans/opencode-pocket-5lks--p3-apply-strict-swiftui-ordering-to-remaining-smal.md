---
# opencode-pocket-5lks
title: P3 apply strict SwiftUI ordering to remaining small view files
status: completed
type: task
priority: low
tags:
    - refactor
    - swiftui
    - cleanup
created_at: 2026-02-21T22:39:38Z
updated_at: 2026-02-21T22:55:59Z
---

Run a strict ordering/conventions pass on smaller SwiftUI files to keep repo-wide consistency.

Target files:
- `OpenCodePocket/Features/RootView.swift`
- `OpenCodePocket/Features/ConnectView.swift`
- `OpenCodePocket/Features/MacConnectView.swift`
- `OpenCodePocket/Features/SessionsView.swift`
- `OpenCodePocket/Features/ChatView.swift`

Scope:
- Reorder declarations to match canonical ordering rules.
- Extract repeated/complex sections into local computed views or tiny private subviews when it improves readability.
- Keep behavior and identifiers stable unless explicitly migrated with test updates.

Acceptance criteria:
- Target files match ordering conventions.
- No functionality changes outside structural cleanup.
- macOS build and iOS tests pass.
