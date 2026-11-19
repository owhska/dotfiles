#!/usr/bin/env bash

install_packages() {
    if (( EUID == 0 )); then
        pacman -S --needed --noconfirm "$@"
    else
        sudo pacman -S --needed --noconfirm "$@"
    fi
}
