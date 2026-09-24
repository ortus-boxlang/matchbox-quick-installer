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

VERSION_FROM_BOX="$(grep -m1 '"version"' "$ROOT/box.json" | cut -d '"' -f 4)"
BRANCH="$(git -C "$ROOT" branch --show-current 2>/dev/null || true)"
if [[ -z "${MVM_VERSION:-}" ]]; then
    MVM_VERSION="$VERSION_FROM_BOX"
    if [[ "$BRANCH" == "main" ]]; then
        MVM_VERSION="${MVM_VERSION%-snapshot}"
    elif [[ "$BRANCH" == "development" && "$MVM_VERSION" != *-snapshot ]]; then
        MVM_VERSION+="-snapshot"
    fi
fi
MVM_COMMIT="${MVM_COMMIT:-$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)}"
MVM_BUILT_ON="${MVM_BUILT_ON:-$(date -u +'%Y-%m-%dT%H:%M:%SZ')}"
OUTPUT="$ROOT/${MVM_OUTPUT:-build/mvm}"
SOURCE="$ROOT/build/mvm.bxs"
mkdir -p "$(dirname "$OUTPUT")"
sed \
    -e "s|^MVM_VERSION = .*;|MVM_VERSION = \"$MVM_VERSION\";|" \
    -e "s|^MVM_COMMIT = .*;|MVM_COMMIT = \"$MVM_COMMIT\";|" \
    -e "s|^MVM_BUILT_ON = .*;|MVM_BUILT_ON = \"$MVM_BUILT_ON\";|" \
    "$ROOT/src/mvm.bxs" > "$SOURCE"
"$MATCHBOX_BIN" --target native --output "$OUTPUT" "$SOURCE"
if [[ "$OUTPUT" != *.exe ]]; then chmod +x "$OUTPUT"; fi
