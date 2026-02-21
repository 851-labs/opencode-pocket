---
# opencode-pocket-hqja
title: P2 migrate MacWorkspace modal presentation to enum-driven sheet(item:) routing
status: completed
type: task
priority: normal
tags:
    - swiftui
    - ui-patterns
    - sheets
    - macos
created_at: 2026-02-21T23:02:28Z
updated_at: 2026-02-21T23:07:49Z
---

Align macOS workspace modal handling with SwiftUI sheet patterns by replacing boolean sheet flags with item-driven modal routing.

Scope:
- Replace `isRenameSheetPresented` and `isAddProjectSheetPresented` in `MacWorkspaceView` with a single enum/item modal state.
- Prefer `.sheet(item:)` where modal state represents a selected modal context.
- Keep sheet content actions self-contained and dismiss via environment dismiss where practical.

Acceptance criteria:
- Mac workspace uses item-driven sheet routing instead of multiple boolean sheet flags.
- Rename/add-project flows keep existing behavior and validation.
- macOS build and iOS tests pass.
