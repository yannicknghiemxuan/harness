#!/usr/bin/env bash
# source:
# - https://www.how2shout.com/linux/install-vscodium-on-ubuntu-22-04-20-04-linux/
set -euxo pipefail

wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
    | sudo tee /etc/apt/sources.list.d/vscodium.list
sudo apt-get update
sudo apt-get install -y codium
