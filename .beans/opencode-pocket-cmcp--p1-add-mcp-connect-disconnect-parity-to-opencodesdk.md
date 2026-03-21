---
# opencode-pocket-cmcp
title: P1 add MCP connect and disconnect parity to OpenCodeSDK
status: completed
type: feature
priority: high
tags:
    - sdk
    - client
    - mcp
    - parity
created_at: 2026-03-20T23:21:08Z
updated_at: 2026-03-21T00:00:28Z
---

`OpenCodeSDK` can already read MCP status, but the app client also uses MCP connect and disconnect controls from its status and settings surfaces.

Scope:
- Add Swift wrappers for `mcp.connect` and `mcp.disconnect`.
- Reuse or extend MCP status models only as needed for these control flows.
- Add focused tests that cover MCP connection actions plus status refresh compatibility.

Acceptance criteria:
- The Swift client can connect and disconnect MCP servers without custom networking.
- MCP action routes are covered by automated tests.
- Required validation passes before the Bean is completed.
