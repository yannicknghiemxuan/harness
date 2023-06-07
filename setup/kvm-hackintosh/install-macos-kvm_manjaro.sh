#!/usr/bin/env bash
# installs mac os in a kvm environment
# creation: 19/07/2019
# modified: 20/07/2019
# expected OS: clean (important!) install of manjaro
# sources:
# (1) https://passthroughpo.st/new-and-improved-mac-os-tutorial-part-1-the-basics/
# (2) https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF
set -euxo pipefail
# high-sierra, mojave, catalina
targetos=high-sierra
qemudir=$HOME/qemu
workdir=$qemudir/macOS-Simple-KVM

# updates the packages and install the dependencies
sudo pacman -Syu --noconfirm
sudo pacman -S openssh emacs-nox
sudo systemctl enable --now sshd
# qemu needs a firewall backend to be installed so installing firewalld
sudo pacman -S qemu python python-pip git virt-manager \
     ebtables dnsmasq firewalld \
     --noconfirm
sudo systemctl enable --now firewalld.service
virsh net-autostart default
sudo systemctl enable --now libvirtd.service virtlogd.service
# need to block the passthrough devices from being used by the OS by using vfio.conf (2)
[[ ! -f /etc/mkinitcpio.conf_orig ]] && sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf_orig
[[ ! -f /etc/modprobe.d/vfio.conf ]] && \
    sudo bash -c 'echo "options vfio-pci ids=$(cat passthroughdevices)" > /etc/modprobe.d/vfio.conf'
# modifying vfio.conf requires to regenerate initramfs (2)
# https://wiki.archlinux.org/index.php/Mkinitcpio#Image_creation_and_activation
presetname=$(ls /etc/mkinitcpio.d/*.preset | awk -F/ '{print $NF}' | awk -F\. '{print $1}')
mkinitcpio -p $presetname
# TODO modify /etc/mkinitcpio.conf
# to avoid this error:
# [ 1930.729028] vfio-pci 0000:05:00.0: BAR 3: can't reserve [mem 0xd0000000-0xd1ffffff 64bit pref]
# sources:
# - https://www.reddit.com/r/VFIO/comments/762lt3/problems_when_booting_host_with_efi/
# - https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF#%22BAR_3:_cannot_reserve_[mem]%22_error_in_dmesg_after_starting_VM
# add 0000:05:00.0 to grub kernel options

# [tnx@achenar macOS-Simple-KVM]$ diff -u /etc/default/grub_orig /etc/default/grub
# --- /etc/default/grub_orig	2019-07-20 12:21:31.853010915 +0100
# +++ /etc/default/grub	2019-07-20 21:52:10.497701041 +0100
# @@ -2,8 +2,8 @@
#  GRUB_TIMEOUT=5
#  GRUB_TIMEOUT_STYLE=menu
#  GRUB_DISTRIBUTOR='Manjaro'
# -GRUB_CMDLINE_LINUX_DEFAULT="quiet"
# -GRUB_CMDLINE_LINUX=""
# +GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt vfio-pci.ids=10de:100a,10de:0e1a,1b73:1100 video=efifb:off"
# +GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt vfio-pci.ids=10de:100a,10de:0e1a,1b73:1100 video=efifb:off"

 # If you want to enable the save default function, uncomment the following
 # line, and set GRUB_DEFAULT to saved.

# now the graphics card is detected in os x by the web drivers but there is no output to it
# https://passthroughpo.st/mac-os-vm-guide-part-2-gpu-passthrough-and-tweaks/
# Make sure you don’t have spice or QXL devices attached

# creates the workspace and clones the git repo and sets the environment
mkdir -p $qemudir
cd $qemu
git clone https://github.com/foxlet/macOS-Simple-KVM.git
cd $workdir
./jumpstart.sh --$targetos
# creates the image for the OS install
qemu-img create -f qcow2 $targetos.qcow2 64G

# first we make a few backups
for i in firmware ESQ.qcow2 basic.sh; do
    if [[ ! -f basic.sh_orig ]]; then
	cp -PRp basic.sh basic.sh_orig
    fi
done

# modifies the content of basic.sh
newmacaddr=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/:$//')
# inserting generated mac address and removing unsupported CPU instructions for Lenovo D30
sed -i \
    -e "s/52:54:00:c9:18:27/${newmacaddr}/" \
    -e 's/+sse4.2,//' -e 's/+avx2,//' \
    basic.sh
cat >> basic.sh <<EOF
    -drive id=SystemDisk,if=none,file=$targetos.qcow2 \\
    -device ide-hd,bus=sata.4,drive=SystemDisk \\
EOF
cat <<EOF
From here you can boot your new VM by running ./basic.sh

Your vm should, after a short while, boot into clover, and then an OS X recovery partition. From here, click “Disk Utility” and format the image you created using the “Erase” button. Be sure not to format the recovery disk or the small partition labeled ESP.

After that, exit disk utility and click “reinstall OS X.”
EOF

lspci -nnk | grep "VGA\|Audio" > auto_video_pci.txt
[[ ! -f /etc/default/grub_orig ]] && sudo cp /etc/default/grub /etc/default/grub_orig
# grub configuration for passthrough

sudo update-grub

