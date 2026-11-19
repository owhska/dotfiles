#!/usr/bin/env bash

install_i3wm() {
    echo "Installing i3wm and its basic components..."

    case "$DISTRO" in
        debian|ubuntu)
            install_packages \
                xorg xinit x11-xserver-utils \
                i3-wm i3status dmenu \
                picom feh network-manager-gnome
            ;;
        arch)
            install_packages \
                xorg-server xorg-xinit xorg-xrandr \
                i3-wm i3status dmenu \
                picom feh network-manager-applet
            ;;
        void)
            install_packages \
                xorg xinit xrandr \
                i3 i3status dmenu \
                picom feh NetworkManager network-manager-applet
            ;;
    esac
}
