#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
. $AUTOROOT/harness/auto/zfs/zfsenv
. $AUTOROOT/rigs/*/config/$(uname -n | awk -F\. '{print $1}')/zfs

for filesystem in $nozfssnaplist; do
    for snap in $(zfs list -r -H -t snapshot -o name $filesystem); do
	# if for any reason snap does not contact a @ character we quit!
	if ! echo $snap | grep '@' >/dev/null 2>&1; then exit 1; fi
	zfs destroy $snap
    done
done
