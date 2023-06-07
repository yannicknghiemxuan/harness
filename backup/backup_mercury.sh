#!/bin/sh
server=mercury
targetdir=/galaxy/public_space/profiles/francoise/$server
[ ! -d $targetdir ] && mkdir -p $targetdir

ping $server
[ $? -ne 0 ] && exit
cd $targetdir && \
rsync -av --exclude .Trash \
    --exclude Cache \
    --exclude Caches \
    --exclude Desktop \
    --exclude Downloads \
    --exclude Movies \
    --exclude 'iTunes Media' \
    --exclude 'iPad Software Updates' \
    --exclude 'VirtualBox VMs' \
    --exclude Frontier_Developments \
    --exclude iDVD \
    --exclude Logs \
    --delete francoise@$server:/Users/francoise/ .
date > $targetdir/lastbackup
