#!/usr/bin/env bash
set -euxo pipefail
mkdir -p /mntsol/s11u3ga /mntsol/s11u3sru /mntsol/s11u3srudelta
for i in $(mount | grep /mntsol | awk '{print $1}'); do umount $i; done
chown -R tnx:staff /mntsol/s11u3ga /mntsol/s11u3sru /mntsol/s11u3srudelta
mount -F hsfs -o ro /rpool/sol_inst/s11u3ga/sol-11_3-repo.iso /mntsol/s11u3ga
mount -F hsfs -o ro /rpool/sol_inst/s11u3sru[0-9]*/sol-11_3_[0-9]*-repo.iso /mntsol/s11u3sru
mount -F hsfs -o ro /rpool/sol_inst/s11u3srudelta[0-9]*/sol-11_3_[0-9]*-repo.iso /mntsol/s11u3srudelta
pkg unset-publisher solaris
pkg set-publisher -p file:///mntsol/s11u3ga/repo
pkg set-publisher -p file:///mntsol/s11u3sru/repo
pkg set-publisher -p file:///mntsol/s11u3srudelta/repo
pkg publisher
