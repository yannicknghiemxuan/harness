#!/bin/sh
server=proteus
targetdir=/galaxy/backup/$server
[ ! -d $targetdir ] && mkdir -p $targetdir

ping $server
[ $? -ne 0 ] && exit
rsync -av --delete root@$server:/etc $targetdir
rsync -av --delete --exclude .mozilla \
    --exclude .cache \
    --exclude .thumbnails \
    --exclude .gvfs \
    root@$server:/home $targetdir
[ ! -d $targetdir/zarafa/var_lib ] && mkdir -p $targetdir/zarafa/var_lib
rsync -av --delete root@$server:/var/lib/zarafa $targetdir/zarafa/var_lib
ssh root@$server /usr/sbin/service mysql stop
rsync -av --delete root@$server:/var/lib/mysql $targetdir/zarafa/var_lib
ssh root@$server /usr/sbin/service mysql start
date > $targetdir/lastbackup
[ ! -d $targetdir/zarafa/iCal_backup/ ] && mkdir -p $targetdir/zarafa/iCal_backup/
curl -X GET -u galaxy_cal:ross154 -H "Accept: text/calendar" http://proteus:8080/caldav/galaxy_cal/ > $targetdir/zarafa/iCal_backup/galaxy_cal.ics
