#!/bin/sh
# Linux distro matrix runner for MVM. Mirrors the BoxLang quick installer suite.

set -eu

REPOSITORY="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
requested_distribution=${1:-}

if os_type="$(docker info --format '{{.OSType}}' 2>/dev/null)" && [ -n "$os_type" ] && [ "$os_type" != "linux" ]; then
    printf '%s\n' 'Docker must be switched to Linux containers.' >&2
    exit 1
fi

run_suite() {
    name="$1"
    image="$2"
    setup="$3"

    printf '\nRunning MVM installer smoke suite in %s\n' "$name"
    docker run --rm \
        -v "$REPOSITORY:/repo:ro" \
        -w / \
        "$image" \
        sh -c "mkdir -p /workspace && $setup && cp -R /repo/. /workspace && cd /workspace && sh tests/run.sh"
}

run_distribution() {
    case "$1" in
        debian)
            run_suite Debian debian:12 \
                'apt-get update >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y bash curl ca-certificates >/dev/null'
            ;;
        ubuntu)
            run_suite Ubuntu ubuntu:24.04 \
                'apt-get update >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y bash curl ca-certificates >/dev/null'
            ;;
        fedora)
            run_suite Fedora fedora:40 \
                'dnf install -y bash curl ca-certificates >/dev/null'
            ;;
        arch)
            run_suite Arch archlinux:latest \
                'pacman -Syu --noconfirm --needed bash curl ca-certificates >/dev/null'
            ;;
        *)
            printf 'Unknown Linux distribution: %s\n' "$1" >&2
            exit 1
            ;;
    esac
}

if [ -n "$requested_distribution" ]; then
    run_distribution "$requested_distribution"
else
    for distribution in debian ubuntu fedora arch; do
        run_distribution "$distribution"
    done
fi

printf '%s\n' 'All Linux distro smoke suites passed.'
