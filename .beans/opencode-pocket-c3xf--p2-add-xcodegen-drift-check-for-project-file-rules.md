---
# opencode-pocket-c3xf
title: P2 add XcodeGen drift check to enforce project file rules
status: cancelled
type: task
priority: normal
tags:
    - xcodegen
    - tooling
    - ci
    - workflow
created_at: 2026-02-22T02:17:54Z
updated_at: 2026-02-22T02:34:17Z
---

AGENTS asks contributors to prefer `project.yml` edits over manual `.pbxproj` changes; this is not currently enforced.

Scope:
- Add a check (script and/or CI step) that regenerates with `xcodegen generate` and fails if tracked project files drift.
- Document the expected workflow when project structure changes.
- Integrate the check with the main validation path.

Acceptance criteria:
- PRs fail when `project.yml` and generated project outputs are out of sync.
- Contributors can run the same check locally.
- Existing project generation flow remains deterministic.
