---
# opencode-pocket-srch
title: P1 add search parity APIs to OpenCodeSDK
status: completed
type: feature
priority: high
tags:
    - sdk
    - parity
    - search
    - models
created_at: 2026-03-21T04:48:08Z
updated_at: 2026-03-21T04:53:08Z
---

The Swift SDK currently exposes file-name search only, while the OpenAPI surface also includes text search and symbol search.

Scope:
- Add `find.text` and `find.symbols` wrappers to `OpenCodeClient`.
- Introduce strongly typed search result models for ripgrep text matches and workspace symbols.
- Keep the API shape aligned with existing search helpers and avoid raw JSON fallbacks unless strictly necessary.

Acceptance criteria:
- The SDK can search file contents and symbols through typed Swift APIs.
- Request-path/query coverage and JSON decoding coverage exist in Swift Testing.
- Required validation passes before completion.
