#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DISTRO="$("$SCRIPT_DIR/detect.sh")"

# Load the package manager implementation for the detected distribution.
# shellcheck source=/dev/null
source "$SCRIPT_DIR/distros/$DISTRO.sh"

# Load available environment installers.
# shellcheck source=/dev/null
source "$SCRIPT_DIR/environments/i3wm.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/environments/sway.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/environments/xfce.sh"

show_menu() {
    printf '\n'
    printf '%s\n' '========================================'
    printf '%s\n' '              SYSTEM SETUP'
    printf '%s\n' '========================================'
    printf '  Distribution: %s\n' "$DISTRO"
    printf '\n'
    printf '%s\n' '  1) i3wm'
    printf '%s\n' '  2) Sway'
    printf '%s\n' '  3) XFCE'
    printf '\n'
    printf '%s\n' '  0) Exit'
    printf '%s\n' '========================================'
}

while true; do
    show_menu
    read -r -p 'Select an environment: ' choice

    case "$choice" in
        1)
            install_i3wm
            break
            ;;
        2)
            install_sway
            break
            ;;
        3)
            install_xfce
            break
            ;;
        0)
            echo 'Setup cancelled.'
            exit 0
            ;;
        *)
            echo 'Invalid option. Try again.'
            ;;
    esac
done

printf '\n%s\n' 'Installation completed.'
printf '%s\n' 'A logout or reboot may be required before using the new environment.'
