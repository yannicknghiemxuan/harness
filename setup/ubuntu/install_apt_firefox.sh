#!/usr/bin/env bash
# source:
# - https://linuxiac.com/install-firefox-from-deb-on-ubuntu-22-04-lts/
set -euxo pipefail
if [[ -f /etc/apt/preferences.d/mozillateamppa ]]; then
    exit 1
fi
snap remove --purge firefox
add-apt-repository ppa:mozillateam/ppa
apt install --target-release 'o=LP-PPA-mozillateam' firefox
cat > /etc/apt/preferences.d/mozillateamppa <<EOF
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 501
EOF
apt-get update
apt-get install -y firefox-esr
