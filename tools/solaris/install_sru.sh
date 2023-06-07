#!/usr/bin/env bash
set -euxo pipefail
sruname=$(ls -d /rpool/sol_inst/s11u3sru* | awk -F/ '{print $NF}' | sort | tail -1 | sed -e 's@delta@@')
curbootadm=$(beadm list -H | grep ';NR;' | awk -F\; '{print $1}')
pkg update --accept
beadm activate $curbootadm
beadm rename ${curbootadm}-1 $sruname
beadm activate $sruname
echo "after rebooting, you could run: beadm rename solaris s11u3ga if this has not been done already"
