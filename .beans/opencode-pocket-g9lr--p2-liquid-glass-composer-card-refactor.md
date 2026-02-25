---
# opencode-pocket-g9lr
title: P2 refactor bottom composer into liquid glass card
status: completed
type: task
priority: normal
tags:
    - ui
    - composer
    - parity
    - liquid-glass
created_at: 2026-02-25T01:16:52Z
updated_at: 2026-02-25T01:24:17Z
---

Refactor the session composer in iOS and macOS workspace views to feel like a card-like Liquid Glass surface, closer to desktop visual language.

Scope:
- Keep existing composer behaviors (send/abort, agent/model/effort selection, status, blocked state messaging).
- Introduce a rounded card treatment with Liquid Glass styling for the core composer input area.
- Preserve prompt/todo cards above the input while improving spacing and hierarchy.

Acceptance criteria:
- Composer appears as a rounded card-like surface with glass styling on iOS and macOS.
- Input, menus, status text, and send/abort action remain functional and accessible.
- macOS build and iOS tests pass.
