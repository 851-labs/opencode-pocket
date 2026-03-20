---
# opencode-pocket-cset
title: P1 add settings, auth, provider, and project parity to OpenCodeSDK
status: todo
type: feature
priority: high
tags:
    - sdk
    - client
    - settings
    - auth
created_at: 2026-03-20T21:50:45Z
updated_at: 2026-03-20T21:50:45Z
---

The app client also needs provider setup and project settings flows beyond the core transcript surface.

Scope:
- Add or complete `provider.list`, `provider.auth`, `provider.oauth.authorize`, `provider.oauth.callback`, `auth.set`, `auth.remove`, `project.list`, `project.current`, `project.update`, `config.get`, and `global.config.update`.
- Ensure the related models match the app client's settings and connection surfaces.
- Keep global-vs-instance config behavior explicit in the Swift API.

Acceptance criteria:
- Swift settings and provider connection flows can use SDK APIs directly.
- Project list/current/update behavior matches the app client's needs.
- Required validation passes.
