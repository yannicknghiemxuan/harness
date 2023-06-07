#!/usr/bin/env bash
set -euxo pipefail
hostname=$(uname -n | awk -F\. '{print $1}')
# we won't mess up with any unindentified system
case $hostname in
    pangea|polux|dragon|yoda)
	DISK=/dev/sdb
	;;
    shibuya)
	DISK=/dev/sda
	;;
    *)
	exit
	;;
esac
sudo rm -rf /var/lib/rook/* || true
sudo sgdisk --zap-all "$DISK"
sudo pvremove -y -ff "$DISK"
sudo wipefs -a "$DISK"
# the sudo dd command crashed the system when I tried, I had to systemctl --force --force reboot
#sudo dd if=/dev/zero of="$DISK" bs=1M count=100 oflag=direct,dsync
# These steps only have to be run once on each node
# If rook sets up osds using ceph-volume, teardown leaves some devices mapped that lock the disks.
ls /dev/mapper/ceph-* | xargs -I% -- sudo dmsetup remove % || true
# ceph-volume setup can leave ceph-<UUID> directories in /dev (unnecessary clutter)
sudo rm -rf /dev/ceph-* || true
# shows if there is still LVM data
sudo blkid /dev/sdb || true
