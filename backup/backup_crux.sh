#!/bin/sh
server=crux
targetdir=/galaxy/backup/$server
[ ! -d $targetdir ] && mkdir -p $targetdir

ping $server
[ $? -ne 0 ] && exit
rsync -av --delete tnx@$server:/galaxy $targetdir
date > $targetdir/lastbackup
