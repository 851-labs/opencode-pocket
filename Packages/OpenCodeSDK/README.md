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

To enforce a lightweight local coverage floor, run:

```bash
Packages/OpenCodeSDK/Scripts/check_coverage.sh
```

By default this checks for at least `98%` line coverage and `96%` function coverage. You can override the thresholds by passing `line` and `function` minimums:

```bash
Packages/OpenCodeSDK/Scripts/check_coverage.sh 99 97
```
