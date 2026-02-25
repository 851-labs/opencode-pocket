---
# opencode-pocket-m5q1
title: P1 decouple preview and mock runtime concerns from app stores
status: completed
type: refactor
priority: high
tags:
  - architecture
  - previews
  - testing
created_at: 2026-02-25T20:18:17Z
updated_at: 2026-02-25T20:25:19Z
---

Remove runtime mock-mode conditionals from `ConnectionStore` and `WorkspaceStore` so app behavior is live-only by default, and move seeded preview behavior to composition-time preview store setup.

Scope:
- Remove `isMockWorkspace` from connection/runtime flow.
- Eliminate mock branches from `WorkspaceStore` methods.
- Introduce explicit store graph factory APIs for live and preview composition.
- Replace `seedMockWorkspace` usage with preview-focused fixture seeding.

Acceptance criteria:
- No `isMockWorkspace` checks remain in app stores.
- Preview setup still renders deterministic seeded data.
- App builds on macOS and iOS simulator.
- SDK tests pass.
