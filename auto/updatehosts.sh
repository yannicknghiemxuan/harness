#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
[[ ! -f /etc/hosts.orig ]] && sudo cp /etc/hosts /etc/hosts.orig
sudo cp /etc/hosts.orig /etc/hosts
if [[ $(uname -n) == "cygnus" ]]; then
    # this is for the nat loopback on the lan
    sudo bash -c "sed -e 's@\s*[a-z]*.irishgalaxy.com@@g' < $AUTOROOT/rigs/*/detail/hosts >> /etc/hosts"
else
    sudo bash -c "cat $AUTOROOT/rigs/*/detail/hosts >> /etc/hosts"
fi
sudo bash -c "$AUTOROOT/harness/auto/generateIPv6hosts >> /etc/hosts"
