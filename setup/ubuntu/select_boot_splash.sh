#!/usr/bin/env bash
set -euxo pipefail
sudo update-alternatives --config default.plymouth
sudo update-initramfs -u
