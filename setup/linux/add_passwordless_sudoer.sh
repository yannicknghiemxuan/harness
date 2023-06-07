#!/usr/bin/env bash
set -euxo pipefail
targetuser=$USER
[[ -n ${1-} ]] && targetuser=${1-} || true
if [[ $targetuser == root ]]; then
    echo "ERROR: target user cannot be root" >&2
    exit 1
fi
sudo bash -c "echo \"${targetuser} ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/$targetuser"
sudo chown root:root /etc/sudoers.d/$targetuser
sudo chmod 440 /etc/sudoers.d/$targetuser
