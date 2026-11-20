#!/bin/sh
# Inner test runner used by tests/run-all.sh inside each Linux distro container.

set -eu

PROJECT_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

if [ -z "${MATCHBOX_BIN:-}" ]; then
    if ! command -v curl >/dev/null 2>&1; then
        printf 'curl is required to install the MatchBox compiler.\n' >&2
        exit 1
    fi
    printf 'Downloading MatchBox compiler for linux-x64...\n'
    curl -fsSL \
        https://github.com/ortus-boxlang/matchbox/releases/latest/download/matchbox-linux-x64 \
        -o /usr/local/bin/matchbox
    chmod +x /usr/local/bin/matchbox
    MATCHBOX_BIN=matchbox
fi
export MATCHBOX_BIN

printf 'Building MVM in the container...\n'
MATCHBOX_BIN="$MATCHBOX_BIN" ./build.sh

MVM_BIN="$PROJECT_ROOT/build/mvm" sh "$PROJECT_ROOT/tests/specs/mvm_install_test.sh"
