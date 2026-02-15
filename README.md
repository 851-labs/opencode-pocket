# opencode-pocket

Native iOS remote-first client for a headless OpenCode server.

> This is a community project and is not affiliated with or built by the OpenCode team.

## Stack

- SwiftUI app target
- Handwritten OpenCode HTTP client (REST + SSE)
- No OpenAPI codegen

## Server compatibility

- Built and tested against OpenCode server `v1.1.65`

## Quick start

1. Generate project files.

```bash
xcodegen generate
```

2. Open the project.

```bash
open OpenCodePocket.xcodeproj
```

3. Build and run on an iOS 26+ simulator.

## Included API surface

- `GET /global/health`
- Session CRUD
- Session messages list/get/send
- `POST /session/:id/prompt_async`
- `POST /session/:id/abort`
- `GET /event` SSE stream

## Security

- Optional Basic Auth support
- Password persisted in Keychain
- ATS exception for `claudl.taile64ce5.ts.net` to permit HTTP for local network use
