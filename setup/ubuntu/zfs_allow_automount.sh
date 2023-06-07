#!/usr/bin/env bash
set -euxo pipefail
# to automount zfs filesystems at boot
sudo systemctl enable --now zfs-import.target
sudo systemctl enable --now zfs-import-cache || true
