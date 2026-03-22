# OpenCodeSDK

`OpenCodeSDK` is the single Swift package module for the app's server client, transport, and typed models.

## Local Verification

Run package tests:

```bash
cd Packages/OpenCodeSDK && swift test
```

Run package tests with coverage and print a file-by-file report:

```bash
Packages/OpenCodeSDK/Scripts/coverage.sh
```

The coverage script runs `swift test --enable-code-coverage` and then uses `llvm-cov report` against `Sources/OpenCodeSDK`.
