#!/bin/sh
# Focused installer/shell smoke test for the Linux distro CI matrix.
# It targets POSIX /bin/sh and invokes bash only for the generated init script.

set -eu

TEST_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_DIR")")"
MVM_BIN="${MVM_BIN:-$PROJECT_ROOT/build/mvm}"
if [ ! -x "$MVM_BIN" ]; then
    printf 'MVM binary is missing or not executable: %s\n' "$MVM_BIN" >&2
    exit 1
fi

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
HOME_DIR="$SANDBOX/home"
MVM_HOME_DIR="$SANDBOX/mvm"
FAKE_BIN="$SANDBOX/bin"
mkdir -p "$HOME_DIR" "$MVM_HOME_DIR" "$FAKE_BIN"

cat > "$FAKE_BIN/curl" <<EOF
#!/bin/sh
while [ \$# -gt 0 ]; do
    if [ "\$1" = "-o" ]; then
        shift
        output=\$1
    fi
    shift
done
cp "$MVM_BIN" "\$output"
EOF
chmod +x "$FAKE_BIN/curl"

FAILURES=0
fail() {
    printf 'FAIL: %s\n' "$1"
    FAILURES=$((FAILURES + 1))
}
assert_contains() {
    case "$2" in
        *"$1"*) : ;;
        *) fail "$3 (expected: $1)" ;;
    esac
}

HOME="$HOME_DIR" \
MVM_HOME="$MVM_HOME_DIR" \
MATCHBOX_HOME="" \
SHELL=/bin/bash \
PATH="$FAKE_BIN:$PATH" \
bash "$PROJECT_ROOT/install/install.sh" >/dev/null

INIT_FILE="$MVM_HOME_DIR/scripts/mvm-init.sh"
PROFILE_FILE="$HOME_DIR/.bashrc"
[ -f "$INIT_FILE" ] || fail "generated init script exists"
[ -f "$PROFILE_FILE" ] || fail "shell profile was updated"
if [ -f "$INIT_FILE" ]; then
    INIT_CONTENTS="$(cat "$INIT_FILE")"
    assert_contains 'MATCHBOX_HOME="${MATCHBOX_HOME:-$HOME/.matchbox}"' "$INIT_CONTENTS" "init declares MATCHBOX_HOME"
    assert_contains 'export MATCHBOX_HOME' "$INIT_CONTENTS" "init exports MATCHBOX_HOME"
    assert_contains '$MATCHBOX_HOME/bin' "$INIT_CONTENTS" "init adds MATCHBOX_HOME/bin"
fi
if [ -f "$PROFILE_FILE" ]; then
    assert_contains '$MVM_HOME/scripts/mvm-init.sh' "$(cat "$PROFILE_FILE")" "profile sources MVM init"
fi

SHELL_COMMAND='source "$HOME/.bashrc"; source "$HOME/.bashrc"; echo "$MATCHBOX_HOME"; echo "$PATH"'
DEFAULT_OUTPUT="$(HOME="$HOME_DIR" MVM_HOME="$MVM_HOME_DIR" MATCHBOX_HOME="" bash --noprofile --norc -c "$SHELL_COMMAND")"
assert_contains "$HOME_DIR/.matchbox" "$DEFAULT_OUTPUT" "MATCHBOX_HOME defaults to ~/.matchbox"
DEFAULT_COUNT="$(printf '%s\n' "$DEFAULT_OUTPUT" | grep -o '[.]matchbox/bin' | wc -l | tr -d ' ')"
[ "$DEFAULT_COUNT" = "1" ] || fail "MATCHBOX_HOME/bin is added exactly once (found $DEFAULT_COUNT)"

CUSTOM_HOME="$SANDBOX/custom-matchbox"
CUSTOM_OUTPUT="$(HOME="$HOME_DIR" MVM_HOME="$MVM_HOME_DIR" MATCHBOX_HOME="$CUSTOM_HOME" bash --noprofile --norc -c "$SHELL_COMMAND")"
assert_contains "$CUSTOM_HOME" "$CUSTOM_OUTPUT" "MATCHBOX_HOME override is preserved"
CUSTOM_COUNT="$(printf '%s\n' "$CUSTOM_OUTPUT" | grep -F -o "$CUSTOM_HOME/bin" | wc -l | tr -d ' ')"
[ "$CUSTOM_COUNT" = "1" ] || fail "custom MATCHBOX_HOME/bin is added exactly once (found $CUSTOM_COUNT)"

if [ "$FAILURES" -ne 0 ]; then
    printf '%s MVM installer smoke assertion(s) failed.\n' "$FAILURES" >&2
    exit 1
fi
printf 'MVM installer smoke test passed.\n'
