---
# opencode-pocket-cov100
title: P1 drive OpenCodeSDK to 100 percent measured coverage
status: in_progress
type: feature
priority: high
tags:
    - sdk
    - testing
    - coverage
    - quality
created_at: 2026-03-22T05:39:31Z
updated_at: 2026-03-22T05:52:20Z
---

`Packages/OpenCodeSDK/Scripts/coverage.sh` currently reports roughly 68 percent line coverage and 64 percent function coverage. The remaining gap is concentrated in model files and helper branches rather than the main route wrappers.

Scope:
- Coordinate the child Beans `covval`, `covdec`, `covlog`, `covcli`, and `covgat`.
- Use `Packages/OpenCodeSDK/Scripts/coverage.sh` as the measurement source of truth.
- Favor targeted, low-flake Swift Testing suites over broad smoke tests.

Acceptance criteria:
- `coverage.sh` reports 100 percent measured coverage for `Packages/OpenCodeSDK/Sources/OpenCodeSDK`.
- `swift test`, macOS build, and iOS simulator build pass.
- The added tests remain organized, deterministic, and maintainable.
