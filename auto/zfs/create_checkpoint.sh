#!/usr/bin/env bash
set -euxo pipefail
. /galaxy/logic/script/zfs/zfsenv
. /galaxy/logic/config/zfs.$(uname -n | awk -F\. '{print $1}')

checkpoint=checkpoint_$($datecmd '+%s_%Y-%m-%d_%Hh%M')h

for VOL in $(zpool list -H -o name,health | grep ONLINE | awk '{print $1}'); do
    zfs snapshot -r ${VOL}@${checkpoint} || true
done
