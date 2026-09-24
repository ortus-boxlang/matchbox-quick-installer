#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_DIR="$ROOT/build/test-results"

cd "$ROOT"
if [[ ! -x "$ROOT/testbox/run" ]]; then
    if ! command -v box >/dev/null 2>&1; then
        echo "TestBox is missing. Install CommandBox, then run 'box install'." >&2
        exit 1
    fi
    box install
fi
./build.sh
rm -rf "$REPORT_DIR"
MVM_BIN="$ROOT/build/mvm" ./testbox/run \
    --directory=tests.specs \
    --reportpath="$REPORT_DIR" \
    --verbose

RESULTS="$REPORT_DIR/TEST.properties"
if ! grep -Eq '^total.specs=[1-9][0-9]*$' "$RESULTS"; then
    echo "TestBox did not discover any integration specs" >&2
    exit 1
fi
if grep -qx 'test.failed=true' "$RESULTS"; then
    exit 1
fi
