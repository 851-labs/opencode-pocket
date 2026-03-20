# App Client Parity Coverage

This package tracks Swift parity against the real opencode app client, not the full server surface.

Regression coverage currently lives in these test entry points:

- `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/OpenCodeClientTests.swift`
  - `endpointsAndSuccessPaths()` exercises the app-driven bootstrap, session, transcript, file-context, settings, and advanced session routes through one stubbed client workflow.
  - focused tests cover pagination, event streaming, archive updates, transport failures, and request encoding edge cases.
- `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/JSONDecodingTests.swift`
  - verifies the richer provider, project, file-context, auth, session-status, and event payload models used by the Swift client.
- `Packages/OpenCodeSDK/Tests/OpenCodeNetworkingTests/RequestBuilderTests.swift`
  - protects request construction, auth headers, and URL behavior.

Required validation for parity work remains:

- `xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination 'platform=macOS' build`
- `xcodebuild -project OpenCodePocket.xcodeproj -scheme OpenCodePocket -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build`
- `cd Packages/OpenCodeSDK && swift test`
