#!/usr/bin/env bash
# sources:
# - https://www.raspberrypi.org/documentation/linux/kernel/building.md
# - https://www.raspberrypi.org/forums/viewtopic.php?t=110337
# - https://andrei.gherzan.ro/linux/raspbian-rpi4-64/
# - https://andrei.gherzan.ro/linux/raspbian-rpi-64/
# - https://www.tal.org/tutorials/raspberry-pi3-build-64-bit-kernel
# enabling rbd module
# - https://ceph.io/planet/rapid-ceph-kernel-module-testing-with-vstart-sh/
set -euxo pipefail
. /etc/autoenv
. $AUTOROOT/harness/tools/raspberry_pi/kernel_compilation/buildenv

sudo apt-get update && \
    sudo apt-get install -y build-essential libgmp-dev libmpfr-dev libmpc-dev \
	 libisl-dev libncurses5-dev bc git-core bison flex texinfo libssl-dev

if [[ ! -d $builddir/binutils ]]; then
    mkdir -p $builddir/binutils
    cd $builddir/binutils
    wget https://ftp.gnu.org/gnu/binutils/binutils-2.34.tar.bz2
    tar xf binutils-2.34.tar.bz2
    mkdir binutils-obj
    cd binutils-obj
    ../binutils-2.34/configure --prefix=/opt/aarch64 --target=aarch64-linux-gnu --disable-nls
    make -j${nbthread}
    sudo make install
fi

if [[ ! -d $builddir/gcc ]]; then
    mkdir -p $builddir/gcc
    cd $builddir/gcc
    wget https://ftp.gnu.org/gnu/gcc/gcc-8.4.0/gcc-8.4.0.tar.xz
    tar xf gcc-8.4.0.tar.xz
    mkdir gcc-out
    cd gcc-out
    ../gcc-8.4.0/configure --prefix=/opt/aarch64 --target=aarch64-linux-gnu --with-newlib --without-headers \
			   --disable-nls --disable-shared --disable-threads --disable-libssp --disable-decimal-float \
			   --disable-libquadmath --disable-libvtv --disable-libgomp --disable-libatomic \
			   --enable-languages=c
    make all-gcc -j${nbthread}
    sudo make install-gcc
    make all-target-libgcc -j${nbthread}
    sudo make install-target-libgcc
fi

cd $builddir
[[ ! -d linux ]] && git clone --depth=1 https://github.com/raspberrypi/linux || true
[[ ! -d ~/tools ]] && git clone https://github.com/raspberrypi/tools ~/tools
mkdir -p kernel-out-$targetrpi || true
cd linux
defcfg=""
case $targetrpi in
    rpi3)
	defcfg=bcmrpi3_defconfig
    ;;
    rpi4)
	defcfg=bcm2711_defconfig
    ;;
esac
make O=../kernel-out-$targetrpi/ ARCH=$arch CROSS_COMPILE=/opt/aarch64/bin/$cross_compile $defcfg
if [[ $domenuconfig == true ]]; then
    cp $AUTOROOT//harness/tools/raspberry_pi/kernel_compilation/$kernconfigfile ../kernel-out-$targetrpi/.config
    make O=../kernel-out-$targetrpi/ ARCH=$arch CROSS_COMPILE=/opt/aarch64/bin/$cross_compile menuconfig
    echo "check the .config file and press a key to start compiling"
    read
fi
echo "compilation of kernel and moduels"
make -j${nbthread} O=../kernel-out-$targetrpi/ ARCH=$arch CROSS_COMPILE=$cross_compile Image modules dtbs
echo "after a git pull of the kernel sources, type:"
echo "  make -j4 O=../kernel-out/ ARCH=$arch CROSS_COMPILE=/opt/aarch64/bin/$cross_compile oldconfig"
