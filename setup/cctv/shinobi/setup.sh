#!/usr/bin/env bash
# instructions:
# - https://shinobi.video/docs/start
# - https://www.youtube.com/watch?v=k7_-dSVihhs
set -euxo pipefail
bash <(curl -s https://gitlab.com/Shinobi-Systems/Shinobi-Installer/raw/master/shinobi-docker.sh)
sudo mkdir /shinobi
if [[ ! -f /etc/fstab_orig ]]; then
    sudo cp /etc/fstab /etc/fstab_orig
    sudo cp fstab /etc
fi
sudo mount /shinobi
