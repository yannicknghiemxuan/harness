#/usr/bin/env bash
set -euxo pipefail

# disables automatic apt-get update
if [[ ! -f /etc/apt/apt.conf.d/10periodic.orig ]]; then
    sudo cp /etc/apt/apt.conf.d/10periodic /etc/apt/apt.conf.d/10periodic.orig
    sudo sed -i 's@APT::Periodic::Update-Package-Lists "1";@APT::Periodic::Update-Package-Lists "0";@g' \
    /etc/apt/apt.conf.d/10periodic
fi
# disables the automatic security upgrades
if [[ ! -f /etc/apt/apt.conf.d/20auto-upgrades.orig ]]; then
    sudo cp /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades.orig
    sudo sed -i 's@APT::Periodic::Unattended-Upgrade "1";@APT::Periodic::Unattended-Upgrade "0";@g' \
    /etc/apt/apt.conf.d/20auto-upgrades
fi
