#!/usr/bin/env bash
set -x
sudo pacman -Syu --noconfirm
sudo pacman -S community/terminator community/ipv6calc community/emacs-nox \
       extra/xterm community/linux-lts-zfs extra/zsh extra/vim mate mate-extra \
       --noconfirm
# to enable zfs after reboot
sudo systemctl enable zfs-import.target
