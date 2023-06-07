#!/usr/bin/env bash
# source:
# - https://openzfs.github.io/openzfs-docs/Getting%20Started/RHEL-based%20distro/index.html#kabi-tracking-kmod
set -euxo pipefail
for directory in /lib/modules/*; do
    kernel_version=$(basename $directory)
    dkms autoinstall -k "$kernel_version"
done
