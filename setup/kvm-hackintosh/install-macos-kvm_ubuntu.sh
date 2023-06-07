#!/usr/bin/env bash
# installs mac os in a kvm environment
# creation: 19/07/2019
# modified: 27/07/2019
# expected OS: clean(important!) install of ubuntu
# execute from ssh through network
# sources:
# (1) https://passthroughpo.st/new-and-improved-mac-os-tutorial-part-1-the-basics/
# (2) https://blog.zerosector.io/2018/07/28/kvm-qemu-windows-10-gpu-passthrough/
set -euxo pipefail
# high-sierra, mojave, catalina
targetos=high-sierra
qemudir=/zdata/vm
workdir=$qemudir/macOS-Simple-KVM

# updates the packages and install the dependencies
sudo apt-get update -y
sudo apt-get dist-upgrade -y
sudo apt-get install -y openssh-server emacs-nox
sudo systemctl enable --now sshd
# qemu needs a firewall backend to be installed so installing firewalld
sudo apt-get install qemu-kvm python python-pip git virt-manager \
     libvirt-clients libvirt-daemon-system bridge-utils virt-manager ovmf \
     ebtables dnsmasq firewalld \
     zsh tmux emacs-nox \
     build-essential git mercurial \
     apt-file apt-utils gparted openssh-server sysstat psmisc \
     terminator pluma xterm xtightvncviewer tightvncserver \
     shimmer-themes clearlooks-phenix-theme lxappearance shiki-colors-metacity-theme tangerine-icon-theme \
     elinks filezilla icedtea-netx samba samba-vfs-modules mdns-scan \
     wmaker wmaker-common wmcpuload wmnet mate-media \
     expect p7zip-full \
     zfsutils-linux \
     -y
sudo systemctl enable --now firewalld.service
sudo firewall-cmd --add-port=5900-5910/tcp --permanent
sudo firewall-cmd --add-port=5900-5910/udp --permanent
sudo systemctl restart firewalld.service
sudo virsh net-autostart default
sudo systemctl enable --now libvirtd.service virtlogd.service
sudo systemctl disable --now lightdm
sudo systemctl disable --now gdm3
sudo systemctl disable --now gdm

# gets the list of devices to passthrough from the user
while [[ -z $passthroughdevices ]]; do
    read -p "please use lspci -nnk to list the passthrough devices in an other terminal and list the IDs comma separated (like 0000:0000,1111:1111)" passthroughdevices
done
echo $passthroughdevices > passthroughdevices

# need to block the passthrough devices from being used by the OS by using vfio.conf (2)
[[ ! -f /etc/mkinitcpio.conf_orig ]] && sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf_orig
[[ ! -f /etc/modprobe.d/vfio.conf ]] && \
    sudo bash -c "echo \"options vfio-pci ids=${passthroughdevices}\" > /etc/modprobe.d/vfio.conf"
# modifying vfio.conf requires to regenerate initramfs
# https://wiki.ubuntu.com/Initramfs
sudo update-initramfs -k all -u -v
# https://wiki.archlinux.org/index.php/Mkinitcpio#Image_creation_and_activation
#presetname=$(ls /etc/mkinitcpio.d/*.preset | awk -F/ '{print $NF}' | awk -F\. '{print $1}')
#mkinitcpio -p $presetname
# TODO modify /etc/mkinitcpio.conf
# to avoid this error:
# [ 1930.729028] vfio-pci 0000:05:00.0: BAR 3: can't reserve [mem 0xd0000000-0xd1ffffff 64bit pref]
# sources:
# - https://www.reddit.com/r/VFIO/comments/762lt3/problems_when_booting_host_with_efi/
# - https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF#%22BAR_3:_cannot_reserve_[mem]%22_error_in_dmesg_after_starting_VM
# add 0000:05:00.0 to grub kernel options

# grub configuration for passthrough
cd /etc/default
[[ ! -f grub_orig ]] && sudo cp grub grub_orig
# if two video cards, add "video=efifb:off" to grub options. This makes kernel
# not use first gpu and boot messages appear on second gpu.
# secondgpuopt=" video=efifb:off"
cat > grub.patch <<EOF
--- grub	2019-07-27 22:33:01.500472129 +0100
+++ grub_next	2019-07-27 22:57:13.253883369 +0100
@@ -6,8 +6,8 @@
 GRUB_DEFAULT=0
 GRUB_TIMEOUT=10
 GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
-GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
-GRUB_CMDLINE_LINUX=""
+GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on iommu=pt vfio-pci.ids=${passthroughdevices}${secondgpuopt}"
+GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt vfio-pci.ids=${passthroughdevices}${secondgpuopt}"

 # Uncomment to enable BadRAM filtering, modify to suit your needs
 # This works with Linux (no patch required) and with any kernel that obtains
EOF
patch grub < grub.patch
sudo update-grub

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

# enable vm autostart, run the same line with --disable to undo
sudo virsh autostart high-sierra
