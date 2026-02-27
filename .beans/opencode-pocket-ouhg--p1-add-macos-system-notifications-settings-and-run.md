---
# opencode-pocket-ouhg
title: P1 add macOS system notifications settings and runtime parity
status: completed
type: feature
priority: high
tags:
    - macos
    - settings
    - notifications
    - parity
    - events
created_at: 2026-02-27T05:17:39Z
updated_at: 2026-02-27T17:15:00Z
---

Add System notifications settings and runtime behavior in OpenCode Pocket with parity to `.local/opencode`.

Scope:
- Add persisted notification settings to ConnectionSettings and wire through ConnectionStore and WorkspaceStore.
- Add a System notifications section in MacSettingsGeneralTab with Agent, Permissions, and Errors toggles using parity copy.
- Implement macOS notification delivery service with authorization handling and safe fallback when denied.
- Trigger notifications from SSE events:
  - permission.asked -> Permissions
  - question.asked and session.idle -> Agent
  - session.error -> Errors
- Avoid noisy notifications while app is focused/active, matching desktop behavior.

Acceptance criteria:
- Toggles render in macOS Settings and persist across relaunch.
- Each toggle gates its matching notification type.
- Notifications fire for matching events when enabled.
- Permission-denied state is handled gracefully without crashes.
- Required validation passes (macOS build, iOS simulator build, OpenCodeSDK tests).

Parity references:
- .local/opencode/packages/app/src/components/settings-general.tsx
- .local/opencode/packages/app/src/context/settings.tsx
- .local/opencode/packages/app/src/pages/layout.tsx
- .local/opencode/packages/app/src/context/notification.tsx
