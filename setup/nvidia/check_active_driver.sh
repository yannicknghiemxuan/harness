#!/usr/bin/env bash
# source:
# - https://askubuntu.com/questions/23238/how-can-i-find-what-video-driver-is-in-use-on-my-system
set -euxo pipefail
sudo lshw -c video
sudo modinfo -F filename `sudo lshw -c video | awk '/configuration: driver/{print $2}' | cut -d= -f2`
sudo modinfo $(sudo modprobe --resolve-alias nvidia)
sudo lspci -nnk | grep -i vga -A3
sudo hwinfo --gfxcard
