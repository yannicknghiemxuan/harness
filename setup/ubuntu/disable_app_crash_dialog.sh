#!/usr/bin/env bash
set -euxo pipefail

# to get rid of the annoying report dialog windows
# source: https://itsfoss.com/how-to-fix-system-program-problem-detected-ubuntu/
if [[ ! -f /etc/default/apport.orig ]]; then
    sudo cp /etc/default/apport /etc/default/apport.orig
    sudo sed -i 's@enabled=1@enabled=0@g' /etc/default/apport
fi
sudo systemctl restart apport
