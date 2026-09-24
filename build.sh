#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MATCHBOX_BIN="${MATCHBOX_BIN:-}"
if [[ -z "$MATCHBOX_BIN" && -x "$ROOT/../matchbox/target/release/matchbox" ]]; then
    MATCHBOX_BIN="$ROOT/../matchbox/target/release/matchbox"
fi
if [[ -z "$MATCHBOX_BIN" ]]; then
    MATCHBOX_BIN="$(command -v matchbox)" || {
        echo "MatchBox is required. Install it or set MATCHBOX_BIN." >&2
        exit 1
    }
fi

mkdir -p "$ROOT/build"
"$MATCHBOX_BIN" --target native --output "$ROOT/build/mvm" "$ROOT/src/mvm.bxs"
chmod +x "$ROOT/build/mvm"
