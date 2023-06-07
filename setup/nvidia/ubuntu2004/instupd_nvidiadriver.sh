#!/usr/bin/env bash
# sources:
# - https://askubuntu.com/questions/260504/how-to-solve-unmet-dependencies-when-installing-nvidia-drivers
# - https://github.com/NVIDIA/nvidia-docker/issues/1243
set -euxo pipefail
target=${1-}
. /etc/autoenv
sudo apt-get update
# sudo ubuntu-drivers list --gpgpu
sudo apt-get remove --purge -y \
     nvidia-* \
     linux-modules-nvidia-* || true
"$AUTOROOT/harness/setup/nvidia/instupd_nvidia_sources.sh"
if [[ -z ${target-} ]]; then
    # latest driver
    sudo ubuntu-drivers install
else
    sudo apt-get install -y nvidia-driver-${target}
fi
sudo apt-get install -y nvidia-container-toolkit
sudo apt-get autoremove -y
sudo systemctl restart docker
