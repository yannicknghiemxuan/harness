#!/usr/bin/env bash
# source:
# - https://openzfs.github.io/openzfs-docs/Getting%20Started/RHEL-based%20distro/index.html#kabi-tracking-kmod
set -euxo pipefail
dnf install https://zfsonlinux.org/epel/zfs-release.el8_5.noarch.rpm
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
dnf install -y epel-release
dnf install -y kernel-devel
dnf install -y zfs
dnf config-manager --disable zfs
dnf config-manager --enable zfs-kmod
dnf install zfs
echo zfs >/etc/modules-load.d/zfs.conf
