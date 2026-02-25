---
# opencode-pocket-m1l7
title: P0 make macOS connect flow managed-local-first with remote fallback
status: completed
type: feature
priority: high
tags:
    - macos
    - connectivity
    - local-server
    - architecture
created_at: 2026-02-25T07:24:37Z
updated_at: 2026-02-25T07:38:40Z
---

Shift macOS from remote-first manual server setup to a managed local OpenCode server flow while preserving a remote fallback mode.

Scope:
- Add a managed local server runtime that can discover `opencode`, launch `opencode serve` on loopback, health-check it, and stop owned processes.
- Add persisted macOS connection mode (`managedLocal` / `remote`) in connection settings.
- Refactor `ConnectionStore` to branch connection logic by mode and auto-connect local mode on launch.
- Update macOS connect/settings UI to expose mode switching and keep remote fallback controls.
- Preserve iOS behavior.

Acceptance criteria:
- macOS can connect to a local server without requiring manual remote URL setup.
- If local mode is selected, app can attach to an existing healthy localhost server or launch its own managed local server.
- Remote fallback remains available.
- iOS connect flow remains unchanged.
- macOS build and iOS tests pass.
