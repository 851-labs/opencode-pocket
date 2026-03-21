---
# opencode-pocket-sgit
title: P2 add project git init parity to OpenCodeSDK
status: todo
type: task
priority: medium
tags:
    - sdk
    - parity
    - project
    - git
created_at: 2026-03-21T04:48:08Z
updated_at: 2026-03-21T04:48:08Z
---

The OpenAPI surface includes project git initialization, but the Swift SDK currently lacks a matching wrapper.

Scope:
- Add `project.initGit` to `OpenCodeClient`.
- Reuse the existing `ProjectInfo` model for the returned refreshed project state.
- Add focused request coverage and any decode regression coverage needed for git-initialized project data.

Acceptance criteria:
- The SDK can initialize git for the current project through a typed API.
- Project git-init behavior is covered by automated tests.
- Required validation passes before completion.
