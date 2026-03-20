---
# opencode-pocket-ctrn
title: P0 add transcript support flows for permissions, questions, and diffs
status: todo
type: feature
priority: high
tags:
    - sdk
    - client
    - transcript
    - interactions
created_at: 2026-03-20T21:50:45Z
updated_at: 2026-03-20T21:50:45Z
---

The app client relies on more than plain transcript messages; it also needs diffs, todos, permissions, and question-response flows.

Scope:
- Add or complete `session.diff` and `session.todo`.
- Add or complete `permission.list`, `permission.reply`, `question.list`, `question.reply`, and `question.reject`.
- Tighten related models so the Swift app can render and answer these flows directly.

Acceptance criteria:
- Transcript-adjacent flows used by the app client are fully available from the SDK.
- App code no longer needs ad hoc request handling for permission/question replies.
- Required validation passes.
