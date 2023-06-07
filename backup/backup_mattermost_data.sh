#!/bin/bash
archname=mattermostdata
rootdir=/home/tnx/work/mattermost
datadir=$rootdir/mattermost-docker/volumes
scriptdir=$rootdir/script
backupdir=$rootdir/backup

rsync -av --delete $datadir $backupdir
rsync -av --delete $scriptdir $backupdir
cd $backupdir
[ -f $archname.tar.gz ] && rm $archname.tar.gz
tar cf $archname.tar volumes && gzip $archname.tar && chmod +r $archname.tar.gz
echo $(date) > $backupdir/backup_date
