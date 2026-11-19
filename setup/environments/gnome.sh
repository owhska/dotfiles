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
        void)
            # Void's gnome-core metapackage is the minimal supported GNOME set.
            # D-Bus and elogind provide the required system/session services.
            install_packages \
                gnome-core dbus elogind \
                nautilus foot
            ;;
    esac
}
