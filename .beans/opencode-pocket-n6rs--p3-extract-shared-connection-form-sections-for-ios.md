---
# opencode-pocket-n6rs
title: P3 extract shared connection form sections for iOS/mac parity
status: completed
type: task
priority: low
tags:
    - swiftui
    - ui-patterns
    - connect
    - refactor
created_at: 2026-02-21T23:03:01Z
updated_at: 2026-02-21T23:26:04Z
---

Reduce duplicated connection-screen UI by extracting shared form sections/components used by both iOS and macOS connect views.

Scope:
- Extract common server/auth/connect-action rows into reusable SwiftUI subviews or helpers.
- Keep platform-specific chrome/layout (NavigationStack vs desktop shell) intact.
- Preserve accessibility identifiers and connection behavior.

Acceptance criteria:
- Duplicate connection form logic is reduced across `ConnectView` and `MacConnectView`.
- Platform-specific presentation remains intact.
- macOS build and iOS tests pass.
