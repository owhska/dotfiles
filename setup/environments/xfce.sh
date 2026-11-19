#!/usr/bin/env bash

install_xfce() {
    echo "Installing XFCE desktop environment..."

    case "$DISTRO" in
        debian|ubuntu)
            install_packages xfce4 xfce4-goodies network-manager-gnome
            ;;
        arch)
            install_packages xorg-server xfce4 xfce4-goodies network-manager-applet
            ;;
    esac
}
