#!/usr/bin/env bash
set -euxo pipefail
server=cygnus
# local target directories
galaxydir=/galaxy/backup/$server/galaxy
etcdir=/galaxy/backup/$server/etc
mattermostdir=/galaxy/galaxy_framework/mattermost/rsynced
openvpndir=/galaxy/galaxy_framework/openvpn/rsynced
nextclouddir=/galaxy/galaxy_framework/nextcloud/rsynced
theprojdir=/galaxy/project/theproj/rsynced
minecraftdir=/galaxy/backup/minecraft
tnxgit=/galaxy/profiles/yannick/rsynced/git
tnxhomedir=/galaxy/backup/$server/tnxhome

mkcd() {
    dir="$1"
    [ -z "$dir" ] && return
    mkdir -p "$dir" && cd "$dir"
    [ $? -ne 0 ] && exit || true
}

mkcd $mattermostdir
ping $server
[ $? -ne 0 ] && exit
# etc
mkcd $etcdir
rsync -av --exclude .zfs --delete root@$server:/etc/ . || true
# galaxy sub-dirs
mkcd $galaxydir
for subdir in data dnsupdate git harness k8shome logic rigs var; do
    rsync -av --exclude .zfs --delete tnx@$server:/galaxy/$subdir . || true
done
# mattermost
mkcd $mattermostdir
rsync -av --exclude .zfs --progress tnx@$server:/zdata/mattermost/backup/mattermostdata.tar.gz . || true
rsync -av --exclude .zfs --delete tnx@$server:/zdata/mattermost/script . || true
scp tnx@$server:/zdata/mattermost/backup/backup_date . || true
# nextcloud
mkcd $nextclouddir
rsync -av --delete --progress \
    --exclude .zfs \
    --exclude partage \
    --exclude files_trashbin \
    root@$server:/zdata/nextcloud/ . || true
echo $(date) > backup_date
# openvpn
mkcd $openvpndir
rsync -av --exclude .zfs --delete --progress \
    root@$server:/zdata/openvpn/ . || true
echo $(date) > backup_date
# theproj
mkcd $theprojdir
rsync -av --exclude .zfs --delete --progress \
    --exclude 'dataset*' \
    tnx@$server:/home/theproj . || true
echo $(date) > backup_date
# rsync -av --delete --progress \
#     tnx@$server:/xdata/theproj/datasetcleaning/ \
#     /galaxy/project/theproj/datasetcleaning/cleanedup || true
# echo $(date) > /galaxy/project/theproj/datasetcleaning/cleanedup/backup_date
# for i in round05 swann_round04; do
#     rsync -av --delete --progress \
# 	  tnx@$server:/home/tnx/theproj/dataset/$i \
# 	  /galaxy/project/theproj/datasetversions/ || true
# done
# echo $(date) > /galaxy/project/theproj/datasetversions/backup_date
# rsync -av --delete --progress \
#     tnx@$server:/home/tnx/theproj/datasetwork/ \
#     --exclude download \
#     /galaxy/project/theproj/datasetwork/ || true
# echo $(date) > /galaxy/project/theproj/datasetwork/backup_date
# tnx git (gnupg + passwords)
mkcd $tnxgit
rsync -av --exclude .zfs --delete tnx@$server:/home/tnx/git/ . || true
echo $(date) > backup_date
# tnx home
mkcd $tnxhomedir
rsync -av --delete --progress \
    --exclude .zfs \
    --exclude cache \
    --exclude .cache \
    --exclude dontsave \
    --exclude 'VirtualBox VMs' \
    --exclude tmp \
    --exclude toatlas \
    --exclude dropboxfs \
    --exclude .thumbnails \
    --exclude Trash \
    --exclude theproj \
    --exclude Downloads \
    --exclude partage \
    tnx@$server:/home/tnx . || true
echo $(date) > backup_date
# minecraft
mkcd $minecraftdir
rsync -av --exclude .zfs --delete --progress tnx@$server:/galaxy/minecraft/ . || true
echo $(date) > backup_date
