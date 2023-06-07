#!/usr/bin/env bash
set -euxo pipefail
# loads all encryption keys and mounts all the filesystems
sudo zpool import -a || true
sudo zfs load-key -a || true
sudo zfs mount -a -l || true
