---
# opencode-pocket-7wtz
title: P2 split WorkspaceView into focused sections and extracted subviews
status: completed
type: task
priority: normal
tags:
    - refactor
    - swiftui
    - ios
    - transcript
created_at: 2026-02-21T22:39:01Z
updated_at: 2026-02-21T22:47:19Z
---

Refactor `OpenCodePocket/Features/WorkspaceView.swift` to follow strict view-ordering and large-file handling guidance.

Scope:
- Keep `WorkspaceView` focused on stored properties/init/body and move helpers into clearly marked private extensions.
- Extract complex computed sections into dedicated private `View` types where state/branching is heavy.
- Preserve existing accessibility IDs and behavior for toolbar, drawer, transcript, composer, and prompt docks.

Acceptance criteria:
- File structure follows ordering rules (state/computed/init/body/subviews/helpers).
- Large-body sections are decomposed without behavior changes.
- Existing UI test identifiers remain stable or are updated with matching test changes.
- macOS build and iOS tests pass.
