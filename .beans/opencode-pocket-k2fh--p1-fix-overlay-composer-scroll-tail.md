---
# opencode-pocket-k2fh
title: P1 fix transcript tail scroll with overlaid composer
status: completed
type: bug
priority: high
tags:
    - ui
    - transcript
    - composer
    - macos
created_at: 2026-02-25T01:37:27Z
updated_at: 2026-02-25T01:41:14Z
---

Fix macOS transcript tail scrolling after introducing the overlaid composer card.

Scope:
- Measure composer height including margins.
- Feed measured inset into transcript rendering.
- Add a bottom spacer node in transcript scroll content and use it as the scroll-to tail target.
- Keep "Jump to latest" visible above the composer.

Acceptance criteria:
- Users can scroll all the way to the latest message.
- Auto-follow and jump-to-latest land below the last visible turn.
- macOS build and iOS tests pass.
