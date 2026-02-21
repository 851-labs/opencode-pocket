---
# opencode-pocket-f4v2
title: P2 project-based sidebar with add-directory workflow and per-project sections
status: completed
type: task
priority: normal
tags:
    - parity
    - navigation
    - sidebar
    - projects
    - ux
created_at: 2026-02-21T18:44:45Z
updated_at: 2026-02-21T19:24:08Z
---

Update the main navigation experience to support multiple projects (directories) like OpenCode desktop, with clear sections per project in the left sidebar.

Scope:
- Add project entities backed by directory paths (name + path + selection state).
- Add sidebar affordance to create/add a project from a directory path.
- Render left sidebar grouped by project, with each project showing its own sessions list section.
- Support project switching so workspace/session queries load for the active project directory.
- Define sensible empty/loading states for no projects and no sessions per project.
- Persist project list and active project across app relaunch.

Acceptance criteria:
- User can add at least one project by choosing/providing a directory.
- Sidebar shows separate project sections with sessions scoped to each project.
- Switching project updates visible sessions/workspace context to that directory.
- Project list and active project persist across relaunch.
- macOS build + iOS tests pass.
