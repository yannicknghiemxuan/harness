#!/bin/zsh
server=aymifa
targetdir=/galaxy/backup/$server
[[ ! -d $targetdir ]] && mkdir -p $targetdir
ping $server
[[ $? -ne 0 ]] && exit
[[ ! -d $targetdir/etc ]] && mkdir -p $targetdir/etc
[[ ! -d $targetdir/home ]] && mkdir -p $targetdir/home

rsync -av --delete tnx@$server:/etc/ $targetdir/etc
rsync -av --delete --exclude .cache --exclude download tnx@$server:/home/ $targetdir/home
date > $targetdir/lastbackup
