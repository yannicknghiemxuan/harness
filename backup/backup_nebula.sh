#!/bin/sh
server=nebula
targetdir=/galaxy/backup/$server
[ ! -d $targetdir ] && mkdir $targetdir
ping $server
[ $? -ne 0 ] && exit
cd /galaxy/public_space/Mirella/autobackup/$server && \
rsync -av --exclude .Trash \
    --exclude .dropbox \
    --exclude Cache \
    --exclude Caches \
    --delete mirella@$server:/Users/mirella .
date > $targetdir/lastbackup
