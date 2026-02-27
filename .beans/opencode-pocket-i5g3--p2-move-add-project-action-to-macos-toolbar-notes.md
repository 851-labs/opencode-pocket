---
# opencode-pocket-i5g3
title: P2 move Add Project action to macOS toolbar (Notes-style)
status: completed
type: task
priority: normal
tags:
    - macos
    - sidebar
    - toolbar
    - ux
    - iconography
created_at: 2026-02-27T05:10:11Z
updated_at: 2026-02-27T17:01:00Z
---

Move the Add Project affordance from the Threads header into the macOS window toolbar, matching Notes-style placement.

Scope:
- Add a toolbar-level Add Project button in MacWorkspaceToolbar.
- Wire the action from MacWorkspaceNavigationShell to present the project picker.
- Remove the Threads header Add Project button in MacWorkspaceSidebar.
- Keep the empty-state Add Project action unchanged.
- Preserve accessibility identifiers (`projects.add`, `projects.add.empty`).

Acceptance criteria:
- Toolbar shows Add Project button in the workspace shell.
- Threads header no longer shows Add Project button.
- Empty state still supports Add Project.
- Toolbar Add Project opens the folder picker and adds project as before.
- Required validation passes (macOS build, iOS simulator build, OpenCodeSDK tests).
