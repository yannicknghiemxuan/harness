#!/bin/sh
server=nix
targetdir=/galaxy/backup/$server
[ ! -d $targetdir ] && mkdir -p $targetdir
ping $server
[ $? -ne 0 ] && exit
[ ! -d $targetdir ] && mkdir -p $targetdir
rsync -av --delete tnx@$server:/galaxy $targetdir
date > $targetdir/lastbackup
