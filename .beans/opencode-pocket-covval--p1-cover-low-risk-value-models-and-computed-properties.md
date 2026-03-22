---
# opencode-pocket-covval
title: P1 cover low-risk value models and computed properties
status: completed
type: task
priority: high
tags:
    - sdk
    - testing
    - coverage
    - models
created_at: 2026-03-22T05:39:31Z
updated_at: 2026-03-22T05:46:59Z
---

Several low-complexity model files still have little or no measured coverage, even though they should be straightforward to cover with direct initializer, computed-property, and Codable tests.

Scope:
- Add focused tests for:
  - `Models/Core/CoreModels.swift`
  - `Models/Workspace/ProjectModels.swift`
  - `Models/Files/FileContextModels.swift`
  - `Models/Files/FindModels.swift`
  - `Models/Providers/ProviderModels.swift`
  - `Models/Tools/SkillModels.swift`
  - `Models/Tools/FormatterModels.swift`
  - `Models/Tools/LSPModels.swift`
  - `Models/Sessions/Session.swift`
- Cover public initializers, coding-key remaps, and computed properties like `id`, `sortTimestamp`, `additionsCount`, and `displayLabel` where applicable.

Acceptance criteria:
- The targeted low-risk model files have direct tests instead of relying on incidental coverage.
- Coverage meaningfully improves without adding brittle test scaffolding.
- Required validation passes before completion.
