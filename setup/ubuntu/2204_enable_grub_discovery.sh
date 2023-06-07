#!/usr/bin/env bash
# source:
# - https://www.omgubuntu.co.uk/2021/12/grub-doesnt-detect-windows-linux-distros-fix
set -euxo pipefail
if [[ ! -f /etc/default/grub_orig ]]; then
    cp /etc/default/grub /etc/default/grub_orig
else
    return
fi
echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
update-grub
