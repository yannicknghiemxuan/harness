#!/usr/bin/env bash
set -euxo pipefail
url='https://releases.mattermost.com/desktop/5.1.0/mattermost-desktop_5.1.0-1_amd64.deb'
TEMP_DEB="$(mktemp)"
wget -O "$TEMP_DEB" "$url"
# dependencies to avoid apt --fix-broken install message
sudo apt-get install -y gconf2 gconf-service
sudo dpkg -i "$TEMP_DEB"
rm -f "$TEMP_DEB"
