#!/usr/bin/env bash
set -euo pipefail

REPOSITORY="ortus-boxlang/matchbox-quick-installer"
MVM_HOME="${MVM_HOME:-$HOME/.mvm}"
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux) PLATFORM="linux" ;;
    Darwin) PLATFORM="macos" ;;
    *) echo "Unsupported operating system: $OS" >&2; exit 1 ;;
esac
case "$ARCH" in
    x86_64|amd64) ARCH="x64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

mkdir -p "$MVM_HOME/bin"
MVM_HOME="$(cd "$MVM_HOME" && pwd)"
export MVM_HOME
INSTALL_DIR="$MVM_HOME/bin"
BINARY="$INSTALL_DIR/mvm"
TEMP_BINARY="$(mktemp "$INSTALL_DIR/.mvm.XXXXXX")"
trap 'rm -f "$TEMP_BINARY"' EXIT
RELEASE_VERSION="${MVM_VERSION:-latest}"
if [[ "$RELEASE_VERSION" == "latest" ]]; then
    URL="https://github.com/$REPOSITORY/releases/latest/download/mvm-$PLATFORM-$ARCH"
else
    RELEASE_VERSION="${RELEASE_VERSION#v}"
    if [[ ! "$RELEASE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?(\+[A-Za-z0-9.-]+)?$ ]]; then
        echo "Invalid MVM version: $RELEASE_VERSION" >&2
        exit 1
    fi
    URL="https://github.com/$REPOSITORY/releases/download/v$RELEASE_VERSION/mvm-$PLATFORM-$ARCH"
fi

curl -fsSL "$URL" -o "$TEMP_BINARY"
chmod +x "$TEMP_BINARY"
mv "$TEMP_BINARY" "$BINARY"
trap - EXIT

export PATH="$INSTALL_DIR:$PATH"
"$BINARY" doctor --fix
echo "MVM installed at $BINARY"
echo "Restart your shell to use MVM in new terminals."
