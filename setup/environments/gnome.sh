#!/usr/bin/env bash

install_gnome() {
    echo "Installing a minimal GNOME desktop..."

    case "$DISTRO" in
        debian|ubuntu)
            install_packages \
                gnome-shell gnome-session \
                gnome-control-center \
                nautilus gvfs \
                foot gnome-keyring
            ;;
        arch)
            install_packages \
                gnome-shell gnome-session \
                gnome-control-center \
                nautilus gvfs \
                foot gnome-keyring
            ;;
    esac
}
