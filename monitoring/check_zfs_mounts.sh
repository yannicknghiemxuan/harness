#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
[[ ${SOURCED_NOTIFY-} != yes ]] && . $AUTOROOT/harness/modules/notify || true

OIFS=$IFS
IFS='
'
for l in $(zfs list -H); do
    fsname=$(echo $l | awk '{print $1}')
    mountpoint=$(echo $l | awk '{print $5}')
    actualfs=$(df -h $mountpoint | grep -v -E '^Filesystem' | awk '{print $1}')
    if [[ -z ${actualfs-} ]]; then
	send_notif \
	    ZFS_MOUNT \
	    $tmpfile \
	    "The zfs filesystem $fsname should be mounted at $mountpoint but this directory could not be found"
    elif [[ $fsname != $actualfs ]]; then
	send_notif \
	    ZFS_MOUNT \
	    $tmpfile \
	    "The zfs filesystem $fsname should be mounted at $mountpoint but $actualfs was found instead"
    fi
done
IFS=$OIFS
