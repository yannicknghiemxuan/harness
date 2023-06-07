#!/usr/bin/env bash
serverip=192.168.0.44
zfs create rpool/sol_inst
zfs set compression=on rpool/sol_inst
mkdir -p /mntsru
cd /rpool/sol_inst
[[ $! -ne 0 ]] && exit
rsync -av --progress \
    --exclude '*.zip' \
    tnx@$serverip:'/galaxy/OS/solaris/solaris_11.3/s11u3ga' .
rsync -av --progress \
    tnx@$serverip:'/galaxy/OS/solaris/solaris_11.3/s11u3sru33_05' .
chown -R tnx:staff /rpool/sol_inst /mntsru
if [[ -f /rpool/sol_inst/s11u3sru33_05/sol-11_3_33_5_0-incr-repo.iso.7z ]]; then
    cd /rpool/sol_inst/s11u3sru33_05/
    7z x sol-11_3_33_5_0-incr-repo.iso.7z && rm sol-11_3_33_5_0-incr-repo.iso.7z
fi
