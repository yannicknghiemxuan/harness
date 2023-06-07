#!/usr/bin/env bash
# source:
# - https://github.com/openzfs/zfs/issues/12747#issuecomment-1064365669
set -euxo pipefail
dnf remove -y zfs
rm /etc/yum.repos.d/zfs.*
dnf reinstall -y https://zfsonlinux.org/epel/zfs-release.el8_5.noarch.rpm
./install_kABI-tracking_kmod_zfs.sh
