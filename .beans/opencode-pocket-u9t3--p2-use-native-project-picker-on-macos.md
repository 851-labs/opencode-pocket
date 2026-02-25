---
# opencode-pocket-u9t3
title: P2 use native macOS directory picker for Add Project
status: completed
type: refactor
priority: medium
tags:
  - macos
  - ux
  - projects
created_at: 2026-02-25T10:12:00Z
updated_at: 2026-02-25T10:28:00Z
---

Replace the custom server directory browser flow in macOS Add Project with the native directory picker.

Scope:
- Launch native folder picker from the toolbar add-project action.
- Remove the custom Add Project and server-browser sheets.
- Remove obsolete project-browser helper code in `WorkspaceStore`.

Acceptance criteria:
- Add Project uses native folder picker only.
- No server-browser UI remains in macOS workspace.
- macOS build and iOS tests pass.
