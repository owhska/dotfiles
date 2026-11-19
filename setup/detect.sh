#!/usr/bin/env bash

# Print the supported distribution ID from /etc/os-release.

if [[ ! -r /etc/os-release ]]; then
    echo "Error: /etc/os-release not found." >&2
    exit 1
fi

. /etc/os-release

case "${ID:-}" in
    debian|ubuntu|arch)
        printf '%s\n' "$ID"
        ;;
    *)
        echo "Error: unsupported distribution '${ID:-unknown}'." >&2
        echo "Supported distributions: Debian, Ubuntu and Arch Linux." >&2
        exit 1
        ;;
esac
