#!/bin/sh
server=haumea
targetdir=/galaxy/profiles/lo/$server
[ ! -d $targetdir ] && mkdir -p $targetdir

ping $server
[ $? -ne 0 ] && exit
cd $targetdir && \
rsync -av --exclude .cache \
    --exclude .compiz \
    --delete lo@$server:/home/lo/ .
date > $targetdir/lastbackup
