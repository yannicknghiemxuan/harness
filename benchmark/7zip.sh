#!/usr/bin/env bash
set -euxo pipefail

. /etc/autoenv
hostname=$(uname -n | awk -F\. '{print $1}')
scorefile=$AUTOROOT/rigs/galaxy/detail/bench_7z
tmpfile=/tmp/7zipbench.$$

7z b -mmt1 | tee $tmpfile
ver=$(grep -E 'p7zip' $tmpfile)
singlescore=$(grep -E '^Tot:' $tmpfile | awk '{print $4}')
rm $tmpfile
7z b | tee $tmpfile
multiscore=$(grep -E '^Tot:' $tmpfile | awk '{print $4}')
grep -v -E $hostname $scorefile > $tmpfile
echo "$hostname;$singlescore;$multiscore;$ver" >> $tmpfile
mv $tmpfile $scorefile
