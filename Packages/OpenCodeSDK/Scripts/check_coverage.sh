#!/usr/bin/env bash
set -euo pipefail

MIN_LINE="${1:-99.9}"
MIN_FUNCTION="${2:-100}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COVERAGE_SCRIPT="$SCRIPT_DIR/coverage.sh"

OUTPUT="$($COVERAGE_SCRIPT)"
TOTAL_LINE="$(printf '%s\n' "$OUTPUT" | grep '^TOTAL')"

printf '%s\n' "$TOTAL_LINE"

python3 - <<'PY' "$TOTAL_LINE" "$MIN_LINE" "$MIN_FUNCTION"
import re
import sys

line = sys.argv[1]
min_line = float(sys.argv[2])
min_func = float(sys.argv[3])
percentages = [float(match) for match in re.findall(r'(\d+\.\d+)%', line)]
if len(percentages) < 3:
    print(f"Unable to parse coverage line: {line}", file=sys.stderr)
    sys.exit(1)

func_cov = percentages[1]
line_cov = percentages[2]

if func_cov < min_func or line_cov < min_line:
    print(
        f"Coverage below threshold: functions={func_cov:.2f}% (min {min_func:.2f}%), lines={line_cov:.2f}% (min {min_line:.2f}%)",
        file=sys.stderr,
    )
    sys.exit(1)
PY
