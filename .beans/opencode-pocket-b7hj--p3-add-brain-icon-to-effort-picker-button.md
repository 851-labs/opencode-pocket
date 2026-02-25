---
# opencode-pocket-b7hj
title: P3 add brain icon to effort picker button
status: completed
type: task
priority: low
tags:
    - ui
    - composer
    - iconography
    - parity
created_at: 2026-02-25T00:12:38Z
updated_at: 2026-02-25T01:05:20Z
---

Add a brain icon to the effort/mode picker button in the composer controls so it matches desktop visual language.

Scope:
- Update the effort picker trigger in iOS and macOS composer views.
- Keep existing menu behavior and selected value text unchanged.
- Ensure icon spacing and alignment are consistent with adjacent controls.

Acceptance criteria:
- Effort picker trigger shows a brain icon next to `Default` / selected effort.
- Trigger remains readable and aligned in both iOS and macOS layouts.
- macOS build and iOS tests pass.
