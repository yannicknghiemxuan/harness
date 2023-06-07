#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
. $AUTOROOT/harness/auto/zfs/zfsenv
. $AUTOROOT/rigs/*/config/$(uname -n | awk -F\. '{print $1}')/zfs

HOUR=$(date '+%H')h

for VOL in $(zpool list -H -o name,health | grep ONLINE | awk '{print $1}'); do
    zfs destroy -r ${VOL}@${HOUR} || true
    zfs snapshot -r ${VOL}@${HOUR} || true
done

$AUTOROOT/harness/auto/zfs/cleardudsnap.sh
