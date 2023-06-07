#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
. $AUTOROOT/harness/auto/zfs/zfsenv
. $AUTOROOT/rigs/*/config/$(uname -n | awk -F\. '{print $1}')/zfs

MONTH=M_$($datecmd '+%B')
for VOL in `zpool list -H -o name,health | grep ONLINE | awk '{print $1}'`; do
    duefile=$snapvardir/scrubpools.$VOL
    if [[ -f $duefile ]]; then
	nextdueepoch=$(cat $duefile)
    else
	nextdueepoch=0
    fi
    todayepoch=$($datecmd --date=today +%s)
    [[ $todayepoch -lt $nextdueepoch && $nextdueepoch -ne 0 ]] && continue
    zpool scrub $VOL &
    epochfirstdayinsixmonth=$($datecmd -d "-$(($($datecmd +%d | sed -e 's@^0*@@g')-1)) days + 3 month" +%s)
    echo $epochfirstdayinsixmonth > $duefile
done
