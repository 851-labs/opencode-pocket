---
# opencode-pocket-k8p2
title: P2 move add project action into Threads header on macOS
status: completed
type: refactor
priority: medium
tags:
  - macos
  - sidebar
  - ux
created_at: 2026-02-25T10:36:00Z
updated_at: 2026-02-25T10:38:30Z
---

Move the Add Project affordance from the top toolbar into the sidebar Threads section header.

Scope:
- Add a header-level add-project button in the Threads section.
- Remove the toolbar-level add-project button.
- Keep an add-project action available when the sidebar is empty.

Acceptance criteria:
- Sidebar Threads header includes add-project button.
- Toolbar no longer includes add-project button.
- Empty state still allows adding a project.
- macOS build and iOS tests pass.
