#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
. $AUTOROOT/harness/tools/raspberry_pi/kernel_compilation/buildenv
echo "example: ./install_kernel_dtbs_modules.sh /media/tnx/3C2A-CBC6 /media/tnx/__"
targetbootpart=$1  # fat32 partition
targetospart=$2    # ext4 partition
mkdir -p $targetbootpart/overlays $targetospart || true
cd $builddir/linux
sudo env PATH=$PATH make O=../kernel-out-$targetrpi/ ARCH=$arch CROSS_COMPILE=$cross_compile INSTALL_MOD_PATH=$targetospart modules_install
sudo cp $targetbootpart/$kernel.img $targetbootpart/$kernel-backup.img || true
cd $builddir/kernel-out-$targetrpi
sudo cp arch/$arch/boot/Image $targetbootpart/$kernel.img
sudo cp arch/$arch/boot/dts/broadcom/*.dtb $targetbootpart/
sudo cp arch/$arch/boot/dts/overlays/*.dtb* $targetbootpart/overlays/
echo done
