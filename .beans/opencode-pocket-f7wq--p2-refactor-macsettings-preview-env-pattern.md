---
# opencode-pocket-f7wq
title: P2 refactor macOS settings previews to shared env pattern
status: completed
type: refactor
priority: medium
tags:
  - macos
  - previews
  - architecture
created_at: 2026-02-25T18:50:51Z
updated_at: 2026-02-25T18:58:43Z
---

Align macOS settings preview setup with a reusable environment-injection pattern inspired by IceCubes while preserving isolated local preview storage.

Scope:
- Refactor preview support to build a dependency graph (connection + workspace).
- Add a single preview environment helper for macOS settings previews.
- Seed preview-safe settings data before building stores.
- Prevent mock-mode workspace persistence side effects.

Acceptance criteria:
- Mac settings previews use one helper instead of repeated environment setup.
- Preview graph setup remains deterministic and isolated from regular app defaults.
- Mock workspace mode does not persist settings.
- macOS build and iOS tests pass.
