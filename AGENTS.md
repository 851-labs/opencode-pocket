# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

## Project Overview

OpenCode Pocket is a native SwiftUI client for a headless OpenCode server.

- Single app target supports iOS and macOS.
- API models and networking are in `Packages/OpenCodeSDK`.
- Networking is handwritten (REST + SSE), not OpenAPI-generated.
- Task tracking uses Beans (`.beans/`, `.beans.yml`).

## Build Commands

### Regenerate Xcode project (when `project.yml` changes)
```bash
xcodegen generate
```

### Build for macOS
```bash
xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination 'platform=macOS' build
```

### Run iOS tests
```bash
xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' test
```

### Run SDK package tests
```bash
cd Packages/OpenCodeSDK && swift test
```

### Code Formatting
The project uses SwiftFormat with 2-space indentation (`.swiftformat`).

## Architecture

### App Layer
- `OpenCodePocket/App`
  - `ConnectionStore`: connection/auth/session wiring
  - `WorkspaceStore`: main workspace state and side effects
  - `AppStore`: top-level composition
- `OpenCodePocket/Features`
  - iOS views (`WorkspaceView`, `ConnectView`)
  - macOS views (`MacWorkspaceView`, `MacConnectView`)
  - shared rendering (`RichMarkdownText`)

### SDK Layer
- `Packages/OpenCodeSDK/Sources/OpenCodeModels`
- `Packages/OpenCodeSDK/Sources/OpenCodeNetworking`

Keep protocol and API behavior in SDK, not in app feature views.

## Modern SwiftUI Architecture Guidelines

### Core Philosophy
- SwiftUI-first, declarative, minimal abstraction.
- Prefer direct state flow over framework-like layers.
- New features should follow current store-driven architecture.

### State Management Rules
Use SwiftUI and Observation wrappers as intended:
- `@State`: local ephemeral view state
- `@Binding`: parent-child state flow
- `@Observable`: shared mutable state containers
- `@Bindable`: binding access to observable stores

### Important Do and Don't
DO:
- Keep side effects in store methods.
- Keep views focused on rendering and dispatching actions.
- Keep state close to where it is needed.
- Preserve existing architecture patterns unless intentionally refactoring.

DON'T:
- Add ViewModels for new features.
- Add unnecessary abstraction layers.
- Use Combine for simple async operations.
- Nest `@Observable` objects inside another `@Observable` without explicit architectural need.

## Platform Boundaries

This project uses one target with platform source exclusions in `project.yml`.

- macOS-specific UI belongs in `Mac*` files and/or `#if os(macOS)`.
- iOS-specific UI belongs in iOS files and/or `#if os(iOS)`.
- If adding platform-specific files, ensure `project.yml` exclusions stay correct.

## OpenCode Parity Workflow

For transcript, composer, and tool rendering behavior, review OpenCode desktop references in:
- `.local/opencode/packages/ui/...`
- `.local/opencode/packages/app/src/pages/session/composer/...`

Prefer parity with OpenCode desktop unless product direction explicitly differs.

## Build Verification Process (Required)

After code changes, agents must:

1. Build macOS target.
2. Run iOS tests.
3. Run `swift test` in `Packages/OpenCodeSDK` when SDK/models/networking changed.
4. Fix compilation/test failures before declaring completion.

## Testing Notes

### UI testing modes
- Workspace mock mode:
  - launch arg: `-ui-testing-workspace`
  - env: `OPENCODE_POCKET_UI_TEST_WORKSPACE=1`
- Connect screen mode:
  - launch arg: `-ui-testing`

### Live integration tests
`OpenCodePocketTests/LiveServerIntegrationTests.swift` honors:
- `OPENCODE_SKIP_LIVE_TESTS=1` to skip
- `OPENCODE_BASE_URL`
- `OPENCODE_USERNAME`
- `OPENCODE_PASSWORD`
- `OPENCODE_DIRECTORY`

## Accessibility and UI Test Contract

- Keep accessibility identifiers stable where possible (`composer.*`, `drawer.*`, `workspace.*`, `message.*`).
- If identifiers or labels change intentionally, update UI tests in the same change.
- Do not silently break existing UI test contracts.

## Security Rules

- Never log plaintext credentials.
- Preserve password storage via Keychain-backed settings store.
- Avoid introducing new insecure persistence paths for secrets.

## Project File Rules

- Prefer editing `project.yml` and regenerate with XcodeGen.
- Avoid manual edits to `OpenCodePocket.xcodeproj/project.pbxproj` unless absolutely necessary.

## Beans Workflow

For non-trivial work:
1. Create or claim Bean.
2. Move Bean status to in-progress.
3. Implement scoped change.
4. Run required validation.
5. Mark Bean completed.
6. Commit with a clear intent-focused message.

Do not mark Beans completed if validation is skipped or failing.

## Definition of Done

A task is done only when:
- Code follows architecture rules above.
- iOS and macOS build/test expectations are satisfied.
- Relevant SDK tests pass when SDK changed.
- Accessibility/test contracts are preserved or updated.
- Bean status is accurate.
- Changes are committed cleanly.
