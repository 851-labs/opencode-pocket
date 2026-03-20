# OpenCode Swift Client Parity

This checklist defines `OpenCodeSDK` parity against the real opencode app client in `.local/opencode/packages/app`, not the entire opencode server or TUI control surface.

## Source Of Truth

- App bootstrap and live sync: `.local/opencode/packages/app/src/context/global-sync/bootstrap.ts`
- App-wide global event wiring: `.local/opencode/packages/app/src/context/global-sync.tsx`
- Prompt submission and session actions: `.local/opencode/packages/app/src/components/prompt-input/submit.ts`
- Session transcript sync: `.local/opencode/packages/app/src/context/sync.tsx`
- File browsing and content loading: `.local/opencode/packages/app/src/context/file.tsx`

## Must-Have For Swift Client Parity

### Bootstrap And Live Sync

- `global.health`
- `global.config.get`
- `global.event`
- `path.get`
- `project.list`
- `project.current`
- `provider.list`
- `provider.auth`
- `config.get`
- `app.agents`

These routes support connection bootstrap, initial workspace hydration, and the app's long-lived global event stream.

### Core Session And Prompt Flow

- `session.create`
- `session.list`
- `session.status`
- `session.get`
- `session.messages`
- `session.prompt_async`

These routes are the core chat lifecycle used by the app client for creating sessions, loading transcript history, and sending prompts.

### Transcript Support Flows

- `session.diff`
- `session.todo`
- `permission.list`
- `permission.reply`
- `question.list`
- `question.reply`
- `question.reject`

These routes back transcript-adjacent UI such as diffs, todos, approval prompts, and user questions.

### File Context And Repo Status

- `file.list`
- `file.read`
- `file.status`
- `find.files`
- `vcs.get`

These routes support file browsing, file previews, path search, and repository status in the app client.

## Phase 2

### Advanced Session Controls

- `session.command`
- `session.shell`
- `session.abort`
- `session.revert`
- `session.unrevert`
- `session.summarize`
- `session.fork`
- `session.share`
- `session.unshare`
- `session.update`
- `session.delete`

### Settings, Providers, And Project Management

- `provider.oauth.authorize`
- `provider.oauth.callback`
- `auth.set`
- `auth.remove`
- `project.update`
- `global.config.update`
- `mcp.status`
- `mcp.connect`
- `mcp.disconnect`

These routes are used by the app client, but they do not block a first complete Swift chat client.

## Out Of Scope For This Parity Track

- `/tui/*`
- `app.log`
- `experimental.workspace.*`
- PTY terminal parity

Those routes either support the TUI/CLI control layer or desktop-terminal features that are outside the current Swift client target.

## Working Rule

When deciding whether to add a new SDK route for this initiative, first confirm it is used by `.local/opencode/packages/app`. If it is only used by the TUI or broader server tooling, it should not expand the Swift client parity scope by default.

## Regression Coverage

- main SDK smoke coverage: `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/OpenCodeClientTests.swift`
- model decoding coverage: `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/JSONDecodingTests.swift`
- transport/request coverage: `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/RequestBuilderTests.swift`
- coverage notes: `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/APP_CLIENT_PARITY_COVERAGE.md`
