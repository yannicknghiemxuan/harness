#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
. $AUTOROOT/harness/auto/zfs/zfsenv
. $AUTOROOT/rigs/*/config/$(uname -n | awk -F\. '{print $1}')/zfs

for VOL in $(zpool list -H -o name,health | grep ONLINE | awk '{print $1}'); do
    duefile=$snapvardir/daily.$VOL
    if [[ -f $duefile ]]; then
	nextdueepoch=$(cat $duefile)
    else
	nextdueepoch=0
    fi
    todayepoch=$($datecmd --date=today +%s)
    [[ $todayepoch -lt $nextdueepoch ]] && continue
    DAY=D_$($datecmd '+%a')
    zfs destroy -r ${VOL}@${DAY} || true
    zfs snapshot -r ${VOL}@${DAY} || true
    epochnextday=$($datecmd +%s -d "next day -$($datecmd +%H) hours -$($datecmd +%M) minutes - $($datecmd +%S) seconds")
    echo $epochnextday > $duefile
done

$AUTOROOT/harness/auto/zfs/cleardudsnap.sh
