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

case "$(basename "${SHELL:-bash}")" in
    bash)
        if [[ "$(uname -s)" == "Darwin" && -f "$HOME/.bash_profile" ]] && ! grep -Fq "# MVM Bash login bridge" "$HOME/.bash_profile"; then
            PROFILE="$HOME/.bash_profile"
        elif [[ "$(uname -s)" == "Darwin" ]]; then
            PROFILE="$HOME/.bashrc"
            if ! grep -Fq "# MVM Bash login bridge" "$HOME/.bash_profile" 2>/dev/null; then
                {
                    printf '\n# MVM Bash login bridge\n'
                    if [[ -f "$HOME/.bash_login" ]]; then
                        printf '[ -r %q ] && . %q\n' "$HOME/.bash_login" "$HOME/.bash_login"
                    elif [[ -f "$HOME/.profile" ]]; then
                        printf '[ -r %q ] && . %q\n' "$HOME/.profile" "$HOME/.profile"
                    fi
                    printf '[ -r %q ] && . %q\n' "$HOME/.bashrc" "$HOME/.bashrc"
                } >> "$HOME/.bash_profile"
            fi
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

if [[ "$(basename "${SHELL:-bash}")" == "bash" ]]; then
    COMPLETION_DIR="$MVM_HOME/completions"
    COMPLETION_FILE="$COMPLETION_DIR/mvm.bash"
    mkdir -p "$COMPLETION_DIR"
    "$BINARY" completion bash > "$COMPLETION_FILE"
    if ! grep -Fq 'MVM_HOME/completions/mvm.bash' "$PROFILE" 2>/dev/null; then
        printf '\n# MVM bash completion\n[ -r "$MVM_HOME/completions/mvm.bash" ] && . "$MVM_HOME/completions/mvm.bash"\n' >> "$PROFILE"
    fi
fi

export PATH="$INSTALL_DIR:$PATH"
echo "MVM installed at $BINARY"
echo "Restart your shell (or source $PROFILE) to use mvm in new terminals."
