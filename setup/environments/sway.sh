#!/usr/bin/env bash

install_sway() {
    echo "Installing Sway and its basic components..."

    case "$DISTRO" in
        debian|ubuntu)
            install_packages \
                sway waybar foot fuzzel \
                swayidle wl-clipboard \
                grim slurp xwayland network-manager-gnome
            ;;
        arch)
            install_packages \
                sway waybar foot fuzzel \
                swayidle wl-clipboard \
                grim slurp xorg-xwayland network-manager-applet
            ;;
    esac
}
