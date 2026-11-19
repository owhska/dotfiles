#!/usr/bin/env bash

install_packages() {
    if (( EUID == 0 )); then
        xbps-install -Sy "$@"
    else
        sudo xbps-install -Sy "$@"
    fi
}
