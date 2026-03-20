---
# opencode-pocket-cfil
title: P0 add file context and repo status parity to OpenCodeSDK
status: todo
type: feature
priority: high
tags:
    - sdk
    - client
    - files
    - vcs
created_at: 2026-03-20T21:50:45Z
updated_at: 2026-03-20T21:50:45Z
---

The app client uses file browsing and repo status APIs to provide context selection and review surfaces.

Scope:
- Add or complete `file.list`, `file.read`, `file.status`, `find.files`, and `vcs.get`.
- Add any missing models for file content, search results, and repo status.
- Keep the SDK surface convenient for the Swift app's file-context stores.

Acceptance criteria:
- The Swift app can browse files, preview content, search paths, and inspect repo status using only SDK APIs.
- Required validation passes.
