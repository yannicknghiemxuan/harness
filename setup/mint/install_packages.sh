#!/usr/bin/env bash
set -x
pkg_cli="zsh tmux emacs-nox"
pkg_build="build-essential git mercurial"
pkg_system="apt-file apt-utils gparted openssh-server sysstat psmisc htop iftop"
pkg_x11tools="terminator pluma xterm xtightvncviewer tightvncserver"
pkg_x11themes="shimmer-themes clearlooks-phenix-theme lxappearance shiki-colors-metacity-theme tangerine-icon-theme"
# icedtea-netx is for java web start
pkg_net="elinks filezilla icedtea-netx samba system-config-samba samba-vfs-modules mdns-scan"
pkg_x11wm="wmaker wmaker-common wmcpuload wmnet mint-meta-mate mate-media"
pkg_tools="expect p7zip-full"
pkg_caodao="blender inkscape"
pkg_multimedia="alsamixergui vlc"
oraclevirtualbox=false

sudo apt-get install -yqq $pkg_cli $pkg_build $pkg_x11tools $pkg_net $pkg_system $pkg_tools $pkg_caodao $pkg_multimedia

# updates the apt database and updates the packages
sudo apt-get update -yqq
[[ $? -ne 0 ]] && exit 1
sudo apt-get dist-upgrade -yqq

# installation of virtualbox
# sources:
# https://www.virtualbox.org/wiki/Linux_Downloads
# http://ubuntuhandbook.org/index.php/2017/10/virtualbox-reached-5-2-major-release-how-to-install/ 
if [[ oraclevirtualbox == true -a  ! -f /etc/apt/sources.list.d/virtualbox.list ]]; then
    echo 'installing Oracle VirtualBox'
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
    mintversion=$(grep 'RELEASE=' /etc/linuxmint/info | awk -F\= '{print $2}')
    # source: https://linuxmint.com/download_all.php
    case $mintversion in
	18*)
	    debianver=xenial
	    ;;
	19*)
	    debianver=bionic
	    ;;
    esac
    sudo sh -c "echo \"deb http://download.virtualbox.org/virtualbox/debian $debianver contrib\" > /etc/apt/sources.list.d/virtualbox.list"
    sudo apt-get update
    sudo apt-get install -yqq virtualbox-5.2
    [[ $? -eq 0 ]] && sudo bash -c 'VBoxManage -v' > /var/log/galaxy.virtualbox
fi

# installation of fonts
mkdir -p ~/.fonts
cd ~/.fonts
if [[ ! -f Monaco-Linux.ttf ]]; then
	wget "https://github.com/hbin/top-programming-fonts/raw/master/Monaco-Linux.ttf"
	sudo fc-cache -fv
fi

# uninstalls the unwanted
# vino works with no other vnc client than gvncviewer
# xed is slow as hell
sudo apt-get remove -yqq vino xed
