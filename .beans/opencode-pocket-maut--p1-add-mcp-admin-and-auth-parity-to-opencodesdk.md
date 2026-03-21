---
# opencode-pocket-maut
title: P1 add MCP admin and auth parity to OpenCodeSDK
status: completed
type: feature
priority: high
tags:
    - sdk
    - parity
    - mcp
    - auth
created_at: 2026-03-21T04:48:08Z
updated_at: 2026-03-21T05:02:18Z
---

The SDK now supports MCP status and connect/disconnect, but it still lacks the MCP add and auth lifecycle routes defined in the OpenAPI spec.

Scope:
- Add `mcp.add`, `mcp.auth.start`, `mcp.auth.callback`, `mcp.auth.authenticate`, and `mcp.auth.remove`.
- Add the typed config and auth models needed to represent MCP add/auth payloads and responses.
- Reuse the existing MCP status models whenever the response contracts already align.

Acceptance criteria:
- The SDK can drive MCP add and auth flows without custom networking.
- Typed request/response coverage exists for the new MCP routes.
- Required validation passes before completion.
