#!/usr/bin/env bash
set -euo pipefail

REPOSITORY="ortus-boxlang/matchbox-quick-installer"
PRODUCT_URL="https://matchbox.boxlang.io/"
MVM_HOME="${MVM_HOME:-$HOME/.mvm}"
MATCHBOX_HOME="${MATCHBOX_HOME:-$HOME/.matchbox}"
export MATCHBOX_HOME

NON_INTERACTIVE=no
if [[ "${MVM_NON_INTERACTIVE:-0}" == "1" || "${MVM_NON_INTERACTIVE:-}" == "true" ]]; then
    NON_INTERACTIVE=yes
fi
for argument in "$@"; do
    case "$argument" in
        -y|--yes|--non-interactive) NON_INTERACTIVE=yes ;;
        -h|--help)
            printf 'Usage: install.sh [--yes]\n\n  --yes, -y, --non-interactive  Install with the recommended defaults without prompts.\n'
            exit 0
            ;;
        *) printf 'Unknown option: %s\n' "$argument" >&2; exit 1 ;;
    esac
done

COLOR_RESET="" COLOR_BOLD="" COLOR_DIM="" COLOR_ACCENT="" COLOR_SUCCESS="" COLOR_WARNING="" COLOR_ERROR=""
RICH_TERMINAL=no
CURSOR_SAVED=no
TEMP_DIR="$(mktemp -d)"
TEMP_BINARY="$TEMP_DIR/mvm-download"

cleanup() {
    rm -f "$TEMP_BINARY"
    rm -rf "$TEMP_DIR"
    if [[ "$CURSOR_SAVED" == "yes" ]]; then
        printf '\0338\033[?25h'
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ -t 1 && -t 2 && "${TERM:-dumb}" != "dumb" && -z "${NO_COLOR:-}" ]]; then
    COLOR_RESET=$'\033[0m' COLOR_BOLD=$'\033[1m' COLOR_DIM=$'\033[2m'
    COLOR_ACCENT=$'\033[36m' COLOR_SUCCESS=$'\033[32m'
    COLOR_WARNING=$'\033[33m' COLOR_ERROR=$'\033[31m'
fi

ANIMATE_LOGO=no
PROMPT_DEVICE=""
if [[ "$NON_INTERACTIVE" == "no" && -t 1 && -r /dev/tty && -w /dev/tty ]]; then
    PROMPT_DEVICE=/dev/tty
    if command -v stty >/dev/null 2>&1; then
        read -r rows columns < <(stty size <"$PROMPT_DEVICE" 2>/dev/null || true)
        if [[ "${rows:-0}" =~ ^[0-9]+$ && "${columns:-0}" =~ ^[0-9]+$ ]] && ((rows >= 24 && columns >= 64)); then
            RICH_TERMINAL=yes
        fi
    fi
fi

if [[ -n "$PROMPT_DEVICE" && -n "$COLOR_RESET" && "${MVM_NO_ANIMATION:-0}" != "1" ]]; then
    ANIMATE_LOGO=yes
fi

declare -a LOGO_LINES=() LOGO_COLORS=()

draw_logo() {
    local i color
    for i in "${!LOGO_LINES[@]}"; do
        if [[ -n "$COLOR_RESET" ]]; then color="${LOGO_COLORS[$i]}"; else color=""; fi
        printf '%b%s%b\n' "$color" "${LOGO_LINES[$i]}" "$COLOR_RESET"
    done
}

show_banner() {
    local -a frame1=(
        '  ▄██████████████████████▄'
        '▄██▀▀          ▄▄      ▀▀██▄'
        '██▀          ▄███        ███'
        '██          ▄█████▄       ██'
        '██     ▄▄   ████████▄     ██'
        '██    ▄███▄ █████████▄    ██'
        '██    ████████  ██████    ██'
        '██    █████▀██   ▀████    ██'
        '██     ████       ███▀    ██'
        '██▄     ▀██▄▄   ▄██▀     ███'
        '▀██▄▄     ▀▀▀▀▀▀▀▀     ▄▄██▀'
        '  ▀██████████████████████▀'
    )
    local -a frame2=(
        '  ▄██████████████████████▄'
        '▄██▀▀          ▄▄      ▀▀██▄'
        '██▀          ▄██        ███'
        '██         ▄█████▄       ██'
        '██     ▄▄   ████████▄     ██'
        '██    ▄███▄ █████████▄    ██'
        '██    ████████  ██████    ██'
        '██    █████▀██   ▀████    ██'
        '██     ████       ███▀    ██'
        '██▄     ▀██▄▄   ▄██▀     ███'
        '▀██▄▄     ▀▀▀▀▀▀▀▀     ▄▄██▀'
        '  ▀██████████████████████▀'
    )
    local -a frame3=(
        '  ▄██████████████████████▄'
        '▄██▀▀         ▄██▄       ▀▀██▄'
        '██▀          ▄████       ███'
        '██          ▄█████▄       ██'
        '██     ▄▄  ▄████████▄     ██'
        '██    ▄███▄██████████▄    ██'
        '██    ████████  ██████    ██'
        '██    █████▀██   ▀████    ██'
        '██     ████       ███▀    ██'
        '██▄     ▀██▄▄   ▄██▀     ███'
        '▀██▄▄     ▀▀▀▀▀▀▀▀     ▄▄██▀'
        '  ▀██████████████████████▀'
    )
    local -a frame4=(
        '  ▄██████████████████████▄'
        '▄██▀▀          ▄▄      ▀▀██▄'
        '██▀          ▄███        ███'
        '██          ▄████▄       ██'
        '██     ▄▄   ████████▄     ██'
        '██    ▄███▄ █████████▄    ██'
        '██    ████████  ██████    ██'
        '██    █████▀██   ▀████    ██'
        '██     ████       ███▀    ██'
        '██▄     ▀██▄▄   ▄██▀     ███'
        '▀██▄▄     ▀▀▀▀▀▀▀▀     ▄▄██▀'
        '  ▀██████████████████████▀'
    )
    LOGO_COLORS=(
        $'\033[38;2;0;255;120m' $'\033[38;2;0;247;140m'
        $'\033[38;2;0;238;158m' $'\033[38;2;0;229;177m'
        $'\033[38;2;0;220;195m' $'\033[38;2;0;211;213m'
        $'\033[38;2;0;201;230m' $'\033[38;2;0;192;247m'
        $'\033[38;2;0;183;255m' $'\033[38;2;0;174;255m'
        $'\033[38;2;0;165;255m' $'\033[38;2;0;155;255m'
        $'\033[38;2;0;148;255m' $'\033[38;2;0;141;255m'
        $'\033[38;2;0;135;255m' $'\033[38;2;0;130;255m'
    )
    local frame round
    printf '\n'
    LOGO_LINES=("${frame1[@]}")
    draw_logo
    if [[ "$ANIMATE_LOGO" == "yes" ]]; then
        for round in 1 2; do
            for frame in 2 3 4 3 2 1; do
                printf '\033[%dA' "${#frame1[@]}"
                case "$frame" in
                    1) LOGO_LINES=("${frame1[@]}") ;;
                    2) LOGO_LINES=("${frame2[@]}") ;;
                    3) LOGO_LINES=("${frame3[@]}") ;;
                    4) LOGO_LINES=("${frame4[@]}") ;;
                esac
                draw_logo
                sleep 0.12
            done
        done
    fi
    printf '\n'
    printf '  %s%sMATCHBOX VERSION MANAGER%s\n' "$COLOR_BOLD" "$COLOR_ACCENT" "$COLOR_RESET"
    printf '  The Rust runtime for BoxLang\n'
    printf '  %s%s%s\n' "$COLOR_DIM" "$PRODUCT_URL" "$COLOR_RESET"
    if [[ -n "$PROMPT_DEVICE" ]]; then
        printf '\n  Interactive installer\n'
    fi
    printf '\n'
}

section() {
    printf '\n  %s%s%s%s\n\n' "$COLOR_ACCENT" "$COLOR_BOLD" "$*" "$COLOR_RESET"
}

divider() {
    if [[ "$RICH_TERMINAL" == "yes" ]]; then
        printf '  %s────────────────────────────────────────────────────────────%s\n' "$COLOR_DIM" "$COLOR_RESET"
    fi
}

info() {
    printf '  %s✓%s  %s\n' "$COLOR_SUCCESS" "$COLOR_RESET" "$*"
}

note() {
    printf '  %s!%s  %s\n' "$COLOR_WARNING" "$COLOR_RESET" "$*" >&2
}

die() {
    printf '  %s×%s  %s\n' "$COLOR_ERROR" "$COLOR_RESET" "$*" >&2
    exit 1
}

run_command() {
    local label="$1" output="$TEMP_DIR/task.log"
    shift
    if "$@" >"$output" 2>&1; then
        info "$label"
    else
        cat "$output" >&2
        die "$label failed"
    fi
}

run_task_progress() {
    local label="$1" output="$TEMP_DIR/progress.log"
    shift
    local pid percent=0 filled bar
    if [[ "$RICH_TERMINAL" != "yes" ]]; then
        run_command "$label" "$@"
        return
    fi
    "$@" >"$output" 2>&1 &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
        percent=$((percent + 2))
        if ((percent > 95)); then percent=95; fi
        filled=$((percent / 4))
        bar=""
        for ((i = 0; i < 25; i++)); do
            if ((i < filled)); then bar+='█'; else bar+='░'; fi
        done
        printf '\r  %s%s%s  %-38s [%s] %3d%%' "$COLOR_ACCENT" '⠋' "$COLOR_RESET" "$label" "$bar" "$percent"
        sleep 0.2
    done
    if wait "$pid"; then
        printf '\r  %s✓%s  %-38s [%s] 100%%\n' "$COLOR_SUCCESS" "$COLOR_RESET" "$label" '█████████████████████████'
    else
        printf '\r\n'
        cat "$output" >&2
        die "$label failed"
    fi
}

read_menu_key() {
    local continuation
    MENU_KEY=""
    IFS= read -rsn1 MENU_KEY <"$PROMPT_DEVICE" || return 1
    if [[ "$MENU_KEY" == $'\033' ]]; then
        if IFS= read -rsn1 -t 0.1 continuation <"$PROMPT_DEVICE"; then
            MENU_KEY+="$continuation"
            if [[ "$continuation" == '[' || "$continuation" == O ]]; then
                IFS= read -rsn1 -t 0.1 continuation <"$PROMPT_DEVICE" || true
                MENU_KEY+="$continuation"
            fi
        fi
    fi
}

select_yes_no() {
    local question="$1" yes_label="$2" no_label="$3" active=0 answer
    local -a labels=("$yes_label" "$no_label")

    if [[ "$RICH_TERMINAL" != "yes" ]]; then
        printf '\n  %s\n\n' "$question"
        printf '  1) %s\n  2) %s\n\n' "$yes_label" "$no_label"
        printf '  Choose [1], or press Enter for 1: ' >"$PROMPT_DEVICE"
        IFS= read -r answer <"$PROMPT_DEVICE" || return 1
        case "$answer" in
            2) return 1 ;;
            q|Q|n|N|no|NO) return 1 ;;
            *) return 0 ;;
        esac
    fi

    printf '\n'
    local prompt_lines=7
    printf '%*s' "$prompt_lines" '' | tr ' ' '\n'
    printf '\033[%dA\0337\033[?25l' "$prompt_lines"
    CURSOR_SAVED=yes
    while true; do
        printf '\0338\033[J'
        printf '  %s%s%s%s\n\n' "$COLOR_BOLD" "$COLOR_ACCENT" "$question" "$COLOR_RESET"
        local i marker color
        for i in "${!labels[@]}"; do
            marker=' ' color="$COLOR_RESET"
            if ((i == active)); then marker='›'; color="$COLOR_ACCENT$COLOR_BOLD"; fi
            printf '  %s%s  %s%s\n' "$color" "$marker" "${labels[$i]}" "$COLOR_RESET"
        done
        printf '\n  %s%s%s\n' "$COLOR_DIM" '↑/↓ choose · Enter continue · Esc skip' "$COLOR_RESET"
        divider
        read_menu_key || return 1
        case "$MENU_KEY" in
            $'\033[A'|$'\033OA'|k) active=0 ;;
            $'\033[B'|$'\033OB'|j) active=1 ;;
            '')
                printf '\0338\033[J\033[?25h'
                CURSOR_SAVED=no
                ((active == 0)) && return 0 || return 1
                ;;
            $'\033'|q|Q|n|N)
                printf '\0338\033[J\033[?25h'
                CURSOR_SAVED=no
                return 1
                ;;
        esac
    done
}

show_system() {
    local system_name="Unknown system"
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        system_name="${PRETTY_NAME:-${ID:-Unknown system}}"
    elif command -v sw_vers >/dev/null 2>&1; then
        system_name="macOS $(sw_vers -productVersion 2>/dev/null)"
    fi
    printf '  %s%s · %s-%s%s\n' "$COLOR_DIM" "$system_name" "$PLATFORM" "$ARCH" "$COLOR_RESET"
}

show_plan() {
    section "Installation plan"
    printf '  Install to %s\n\n' "$MVM_HOME"
    printf '  %s+%s  MVM version manager and launchers\n' "$COLOR_ACCENT" "$COLOR_RESET"
    printf '  %s+%s  Shell integration for the detected shell\n' "$COLOR_ACCENT" "$COLOR_RESET"
    printf '  %s+%s  MATCHBOX_HOME at %s\n' "$COLOR_ACCENT" "$COLOR_RESET" "$MATCHBOX_HOME"
    printf '  %s+%s  Add MVM and MatchBox bin directories to PATH\n' "$COLOR_ACCENT" "$COLOR_RESET"
}

install_runtime() {
    section "Installing MatchBox"
    run_task_progress "Downloading MatchBox" "$BINARY" install latest
    run_command "Activated the latest MatchBox" "$BINARY" use latest
    printf '\n  MatchBox is ready.\n'
}

profile_source_hint() {
    local shell_name="${SHELL##*/}"
    case "$shell_name" in
        zsh) printf 'source ~/.zshrc' ;;
        fish) printf 'source ~/.config/fish/config.fish' ;;
        *) printf 'source ~/.bashrc' ;;
    esac
}

show_summary() {
    section "MVM is ready"
    info "MVM installed at $BINARY"
    printf '\n  To use MVM in this terminal:\n'
    printf '    %s\n' "$(profile_source_hint)"
    printf '\n  %sQuick start:%s\n' "$COLOR_BOLD" "$COLOR_RESET"
    printf '    mvm install latest\n    mvm use latest\n    matchbox --version\n'
    printf '\n  %sLearn more: %s%s\n\n' "$COLOR_DIM" "$PRODUCT_URL" "$COLOR_RESET"
}

show_banner

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
    Linux) PLATFORM="linux" ;;
    Darwin) PLATFORM="macos" ;;
    *) die "Unsupported operating system: $OS" ;;
esac
case "$ARCH" in
    x86_64|amd64) ARCH="x64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) die "Unsupported architecture: $ARCH" ;;
esac
show_system

mkdir -p "$MVM_HOME/bin"
MVM_HOME="$(cd "$MVM_HOME" && pwd)"
export MVM_HOME
INSTALL_DIR="$MVM_HOME/bin"
BINARY="$INSTALL_DIR/mvm"

RELEASE_VERSION="${MVM_VERSION:-latest}"
if [[ "$RELEASE_VERSION" == "latest" ]]; then
    URL="https://github.com/$REPOSITORY/releases/latest/download/mvm-$PLATFORM-$ARCH"
else
    RELEASE_VERSION="${RELEASE_VERSION#v}"
    if [[ ! "$RELEASE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?(\+[A-Za-z0-9.-]+)?$ ]]; then
        die "Invalid MVM version: $RELEASE_VERSION"
    fi
    URL="https://github.com/$REPOSITORY/releases/download/v$RELEASE_VERSION/mvm-$PLATFORM-$ARCH"
fi

show_plan
section "Installing MVM"
run_command "Detected $PLATFORM-$ARCH" true
run_command "Downloaded MVM $RELEASE_VERSION" curl -fsSL "$URL" -o "$TEMP_BINARY"
chmod +x "$TEMP_BINARY"
mv "$TEMP_BINARY" "$BINARY"
info "Installed MVM to $BINARY"

export PATH="$INSTALL_DIR:$PATH"
run_command "Configured shell integration" "$BINARY" doctor --fix

if [[ "$NON_INTERACTIVE" == "yes" ]]; then
    install_runtime
elif [[ -n "$PROMPT_DEVICE" ]]; then
    if select_yes_no \
        "Install the latest MatchBox runtime now?" \
        "Yes, install and use it" \
        "No, maybe later"; then
        install_runtime
    else
        printf '\n  MatchBox install skipped. Install it later with:\n'
        printf '    mvm install latest\n'
        printf '    mvm use latest\n'
        printf '\n  %sLearn more: %s%s\n\n' "$COLOR_DIM" "$PRODUCT_URL" "$COLOR_RESET"
        exit 0
    fi
fi

show_summary
