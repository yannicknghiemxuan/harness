#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
. $AUTOROOT/harness/auto/zfs/zfsenv
. $AUTOROOT/rigs/*/config/$(uname -n | awk -F\. '{print $1}')/zfs

for VOL in $(zpool list -H -o name,health | grep ONLINE | awk '{print $1}'); do
    duefile=$snapvardir/monthly.$VOL
    if [[ -f $duefile ]]; then
	nextdueepoch=$(cat $duefile)
    else
	nextdueepoch=0
    fi
    todayepoch=$($datecmd --date=today +%s)
    [[ $todayepoch -lt $nextdueepoch && $nextdueepoch -ne 0 ]] && continue
    MONTH=M_$($datecmd '+%B')
    zfs destroy -r ${VOL}@${MONTH} || true
    zfs snapshot -r ${VOL}@${MONTH} || true
    epochfirstdaynextmonth=$($datecmd -d "-$(($($datecmd +%d | sed -e 's@^0*@@g')-1)) days + 1 month" +%s)
    echo $epochfirstdaynextmonth > $duefile
done

$AUTOROOT/harness/auto/zfs/cleardudsnap.sh
