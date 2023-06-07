#!/bin/env bash
server=shinrarta
targetdir=/galaxy/backup/$server
[ ! -d $targetdir ] && mkdir -p $targetdir

ping $server
[ $? -ne 0 ] && exit
cd /galaxy/profiles/mirella/autobackup/$server/mirella && \
rsync -av --exclude .Trash \
    --exclude Cache \
    --exclude Caches \
    --exclude cache \
    --exclude Downloads \
    --exclude Dropbox \
    --exclude Movies \
    --exclude 'iTunes Media' \
    --exclude 'iPad Software Updates' \
    --exclude 'VirtualBox VMs' \
    --exclude Frontier_Developments \
    --exclude iDVD \
    --exclude Logs \
    --delete mirella@$server:/Users/mirella/ .
date > $targetdir/lastbackup
