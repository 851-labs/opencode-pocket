---
# opencode-pocket-t8hk
title: P1 expand environment injection through connect and workspace trees
status: completed
type: refactor
priority: high
tags:
    - architecture
    - swiftui
    - dependency-injection
    - connect
    - workspace
created_at: 2026-02-25T05:47:01Z
updated_at: 2026-02-25T05:58:20Z
---

Expand the environment injection pattern from app root/settings pilot into the main connect and workspace feature trees.

Scope:
- Convert connect views/components to read `ConnectionStore` from `@Environment`.
- Convert workspace views/components/sheets/composer/prompt cards to read `WorkspaceStore` from `@Environment`.
- Remove redundant `store` initializer parameters and update call sites accordingly.
- Preserve behavior and accessibility identifiers.

Acceptance criteria:
- Connect and workspace flows compile without explicit store prop-drilling in view initializers.
- Runtime behavior is unchanged.
- macOS build and iOS tests pass.
