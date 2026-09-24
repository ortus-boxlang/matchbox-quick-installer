#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MATCHBOX_BIN="${MATCHBOX_BIN:-}"
if [[ -z "$MATCHBOX_BIN" && -x "$ROOT/../matchbox/target/release/matchbox" ]]; then
    MATCHBOX_BIN="$ROOT/../matchbox/target/release/matchbox"
fi
MATCHBOX_BIN="${MATCHBOX_BIN:-$(command -v matchbox)}"
TEMP_HOME="$(mktemp -d)"
REPORT_DIR="$ROOT/build/test-results"
trap 'rm -rf "$TEMP_HOME"' EXIT

cd "$ROOT"
mkdir -p build
"$MATCHBOX_BIN" --target native --output build/mvm src/mvm.bxs
chmod +x build/mvm
rm -rf "$REPORT_DIR"
MVM_HOME="$TEMP_HOME" MVM_BIN="$ROOT/build/mvm" ./testbox/run \
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
