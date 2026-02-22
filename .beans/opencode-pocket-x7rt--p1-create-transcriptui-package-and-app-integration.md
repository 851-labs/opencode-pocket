---
# opencode-pocket-x7rt
title: P1 create TranscriptUI package and app integration
status: completed
type: task
priority: high
tags:
    - architecture
    - package
    - transcript
    - markdown
created_at: 2026-02-22T21:08:24Z
updated_at: 2026-02-22T21:21:00Z
---

Create a focused `TranscriptUI` Swift package for transcript rendering so markdown and message presentation can evolve independently from app feature screens.

Scope:
- Add local package target(s) and wire into `project.yml` / generated project.
- Define stable public view API for transcript markdown rendering used by iOS and macOS message cards.
- Keep behavior unchanged until migration beans land.

Acceptance criteria:
- App compiles with `TranscriptUI` linked on all supported platforms.
- Existing transcript behavior is unchanged after this scaffolding step.
- Required validation passes (macOS build, iOS tests).
