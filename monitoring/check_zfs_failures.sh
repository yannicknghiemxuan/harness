#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
[[ ${SOURCED_NOTIFY-} != yes ]] && . $AUTOROOT/harness/modules/notify || true

# condition found in https://gist.github.com/petervanderdoes/bd6660302404ed5b094d
zfserror=$(sudo zpool status \
	       | grep -i -E '(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED|corrupt|cannot|unrecover)' \
	       | egrep -v 'some features are unavailable' \
	       || true)
[[ -z ${zfserror-} ]] && exit 0
sudo zpool status -x > /tmp/check_zfs_failures.$$
send_notif_and_file \
    ZPOOL_ERROR \
    /tmp/check_zfs_failures.$$ \
    "zpool errors have been detected:

$(cat /tmp/check_zfs_failures.$$)"
