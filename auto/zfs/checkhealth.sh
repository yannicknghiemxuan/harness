#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
. /galaxy/logic/config/zfs.$(uname -n | awk -F\. '{print $1}')

HOSTNAME=`hostname`
DATE=`date '+%d/%m/%Y_%Hh%M'`
SUBJECT="${HOSTNAME}:_ZFS_ERROR_DETECTED_$DATE"
UPTIME=`uptime`
CONFIGFILE=/galaxy/logic/config/report.conf
REPORTFILE=/tmp/${HOSTNAME}_report
LOGFILE=/galaxy/logic/log/reportgen.log

sendreport() {
TARGET=`grep "^target=" $CONFIGFILE | awk -F= {'print $2'}`
SMTPSERVER=`grep "^smtpserver=" $CONFIGFILE | awk -F= {'print $2'}`
SENDER=`grep "^sender=" $CONFIGFILE | awk -F= {'print $2'}`
/galaxy/apps/bin/smtpmail -v -v -q -s $SUBJECT -t $TARGET -H $SMTPSERVER -f $SENDER $REPORTFILE 2> $LOGFILE
}

generatereport() {
rm -f $REPORTFILE 2> /dev/null
touch $REPORTFILE
chmod 600 $REPORTFILE

cat >> $REPORTFILE <<EOA
===================================================
| Galaxy Network
===================================================
| ${HOSTNAME}: ZFS errors detected
===================================================
date: ${DATE}
uptime: ${UPTIME}

EOA
cat >> $REPORTFILE <<EOF

*** ZFS pools status ***
EOF
zpool status -x >> $REPORTFILE
zpool status -v >> $REPORTFILE
zpool iostat >> $REPORTFILE
}

zpool status -x | grep health >/dev/null 2>&1
if [ $? -eq 0 ]; then
    exit 0
fi

generatereport
sendreport
