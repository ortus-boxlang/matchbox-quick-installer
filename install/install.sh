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
INSTALL_DIR="$MVM_HOME/bin"
BINARY="$INSTALL_DIR/mvm"
TEMP_BINARY="$(mktemp "$INSTALL_DIR/.mvm.XXXXXX")"
trap 'rm -f "$TEMP_BINARY"' EXIT
URL="https://github.com/$REPOSITORY/releases/latest/download/mvm-$PLATFORM-$ARCH"

curl -fsSL "$URL" -o "$TEMP_BINARY"
chmod +x "$TEMP_BINARY"
mv "$TEMP_BINARY" "$BINARY"
trap - EXIT

case "$(basename "${SHELL:-bash}")" in
    bash)
        if [[ "$(uname -s)" == "Darwin" && -f "$HOME/.bash_profile" ]]; then
            PROFILE="$HOME/.bash_profile"
        else
            PROFILE="$HOME/.bashrc"
        fi
        ;;
    zsh) PROFILE="$HOME/.zshrc" ;;
    fish) PROFILE="$HOME/.config/fish/config.fish" ;;
    *) PROFILE="$HOME/.profile" ;;
esac
mkdir -p "$(dirname "$PROFILE")"
if ! grep -Fq "# MVM" "$PROFILE" 2>/dev/null; then
    if [[ "$(basename "${SHELL:-bash}")" == "fish" ]]; then
        printf '\n# MVM\nset -gx MVM_HOME "%s"\nset -gx PATH "$MVM_HOME/bin" $PATH\n' "$MVM_HOME" >> "$PROFILE"
    else
        printf '\n# MVM\nexport MVM_HOME=%q\nexport PATH="$MVM_HOME/bin:$PATH"\n' "$MVM_HOME" >> "$PROFILE"
    fi
fi

export MVM_HOME
export PATH="$INSTALL_DIR:$PATH"
echo "MVM installed at $BINARY"
echo "Restart your shell (or source $PROFILE) to use mvm in new terminals."
