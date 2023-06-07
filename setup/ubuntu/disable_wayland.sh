#!/usr/bin/env bash
# source:
# - https://linuxconfig.org/how-to-disable-wayland-and-enable-xorg-display-server-on-ubuntu-18-04-bionic-beaver-linux
set -euxo pipefail
[[ /etc/gdm3/custom.conf_orig ]] && \
    sudo cp /etc/gdm3/custom.conf /etc/gdm3/custom.conf_orig
sudo sed -i 's@#WaylandEnable=false@WaylandEnable=false@' /etc/gdm3/custom.conf
sudo systemctl restart gdm3
