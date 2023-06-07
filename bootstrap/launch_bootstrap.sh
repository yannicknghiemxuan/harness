#!/usr/bin/env bash
set -x
. /etc/autoenv
hostname=$(uname -n)
logfilepath=$AUTOROOT/log/bootstrap
logfile=$logfilepath/bootstrap.log
sudo rm -f $logfile >/dev/null 2>&1 || true
mkdir -p $logfilepath || true
for s in $AUTOROOT/rigs/*/config/$hostname/script/bootstrap.sh; do
    sudo bash -c "echo \"=== $(date): STARTING BOOTSTRAP SCRIPT: $s\" >> $logfile"
    sudo bash -c "$s >> $logfile 2>&1" || true
    sudo bash -c "echo \"=== $(date): ENDING BOOTSTRAP SCRIPT: $s\" >> $logfile"
done
