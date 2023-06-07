#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
. $AUTOROOT/harness/auto/zfs/zfsenv
. $AUTOROOT/rigs/*/config/$(uname -n | awk -F\. '{print $1}')/zfs

for VOL in $(zpool list -H -o name,health | grep ONLINE | awk '{print $1}'); do
    duefile=$snapvardir/weekly.$VOL
    if [[ -f $duefile ]]; then
	nextdueepoch=$(cat $duefile)
    else
	nextdueepoch=0
    fi
    todayepoch=$($datecmd --date=today +%s)
    [[ $todayepoch -lt $nextdueepoch && $nextdueepoch -ne 0 ]] && continue || true
    zfs destroy -r ${VOL}@W_3weeks 2> /dev/null || true
    zfs rename -r ${VOL}@W_2weeks ${VOL}@W_3weeks || true
    zfs rename -r ${VOL}@W_1week ${VOL}@W_2weeks || true
    zfs rename -r ${VOL}@W_thisweek ${VOL}@W_1week || true
    zfs snapshot -r ${VOL}@W_thisweek || true
    epochnextweek=$($datecmd -d "next week" +%s)
    echo $epochnextweek > $duefile
done

$AUTOROOT/harness/auto/zfs/cleardudsnap.sh
