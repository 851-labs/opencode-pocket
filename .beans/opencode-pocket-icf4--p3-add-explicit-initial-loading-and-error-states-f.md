---
# opencode-pocket-icf4
title: P3 add explicit initial loading and error states for workspace bootstrap
status: completed
type: task
priority: normal
tags:
    - swiftui
    - ui-patterns
    - loading
    - ux
created_at: 2026-02-21T23:02:50Z
updated_at: 2026-02-21T23:16:40Z
---

Align with loading/placeholders guidance by making workspace bootstrap state explicit during initial model/session refresh.

Scope:
- Add an explicit initial load state for `WorkspaceView` and `MacWorkspaceView` while `.task` refresh work is in progress.
- Surface fetch failures with clear retry affordances instead of only relying on empty-state fallthrough.
- Preserve current steady-state behavior once data is loaded.

Acceptance criteria:
- Initial load shows a deterministic loading state (not ambiguous empty state).
- Initial load failures show actionable error/retry UI.
- macOS build and iOS tests pass.
