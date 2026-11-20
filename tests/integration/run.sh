#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT_DIR="$ROOT/build/test-results"
RUNNER="$ROOT/testbox/system/runners/BoxLangRunner.bx"

cd "$ROOT"
if [[ ! -f "$RUNNER" && ! -f "$ROOT/testbox/run" ]]; then
    if ! command -v box >/dev/null 2>&1; then
        echo "TestBox is missing. Install CommandBox, then run 'box install'." >&2
        exit 1
    fi
    box install
fi

MVM_EXE=""
if [[ "${RUNNER_OS:-}" == "Windows" || "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* ]]; then
    MVM_EXE=".exe"
fi

if [[ -z "${MATCHBOX_BIN:-}" ]]; then
    if [[ -n "$MVM_EXE" ]] && command -v matchbox.exe >/dev/null 2>&1; then
        MATCHBOX_BIN="matchbox.exe"
    elif command -v matchbox >/dev/null 2>&1; then
        MATCHBOX_BIN="matchbox"
    fi
fi
if [[ -z "$MATCHBOX_BIN" ]]; then
    echo "MatchBox is missing. Install it or set MATCHBOX_BIN." >&2
    exit 1
fi
export MATCHBOX_BIN
MVM_BINARY="$ROOT/build/mvm$MVM_EXE"
MVM_OUTPUT="build/mvm$MVM_EXE" ./build.sh

PYTHON_BIN="${PYTHON_BIN:-}"
if [[ -z "$PYTHON_BIN" ]]; then
    PYTHON_BIN="$(command -v python3 || command -v python || true)"
fi
if [[ -z "$PYTHON_BIN" ]]; then
    echo "Python is required for the release install test." >&2
    exit 1
fi
"$PYTHON_BIN" tests/integration/test_release_install.py

rm -rf "$REPORT_DIR"
if [[ -f "$ROOT/testbox/run" ]]; then
    RUNNER_COMMAND=(bash "$ROOT/testbox/run")
else
    RUNNER_COMMAND=("${BOX_LANG_BIN:-boxlang}" "$RUNNER")
fi
MVM_BIN="$MVM_BINARY" "${RUNNER_COMMAND[@]}" \
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
