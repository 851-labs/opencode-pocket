---
# opencode-pocket-jqbs
title: P2 replace variant-count model labels with composer thinking-effort picker
status: completed
type: task
priority: normal
tags:
    - parity
    - composer
    - models
    - ux
created_at: 2026-02-21T18:39:10Z
updated_at: 2026-02-21T19:03:22Z
---

Align native composer model controls with OpenCode desktop by removing variant-count labels from model names and adding a dedicated thinking-effort picker in the bottom composer.

Scope:
- Remove "(N variants)" suffix from model menu entries in iOS and macOS composer model pickers.
- Add a composer thinking-effort menu (Default + model variants) beside the model picker in iOS and macOS.
- Keep the same treatment across both platforms.
- Use selected effort when sending prompts (`PromptRequest.variant`).
- Persist selected effort in connection/workspace settings.

Acceptance criteria:
- Composer model list no longer displays variant-count suffixes.
- Composer shows thinking-effort picker in the bottom tray, with `Default` selected by default.
- Effort options reflect selected model variants from provider config.
- Changing effort affects outbound prompt payload (`variant`) and is retained across relaunch/reconnect.
- macOS build + iOS tests pass.
