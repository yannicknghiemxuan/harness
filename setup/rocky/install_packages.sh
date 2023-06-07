#!/usr/bin/env bash
set -x
yum upgrade -y

# disable the firewall
#systemctl disable firewalld -> might be actually needed for docker swarm

###  additional repos
# EPEL (Extra Packages for Enterprise Linux) repo (to get things like 7zip)
yum -y install epel-release
# ELRepo - filesystem drivers, graphics drivers, network drivers, sound drivers, webcam and video drivers
#   source: http://elrepo.org/tiki/tiki-index.php
# NUX Repos - https://li.nux.ro/repos.html
#   Desktop
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm

# zfs install
yum install -y http://download.zfsonlinux.org/epel/zfs-release.el7_5.noarch.rpm
yum autoremove
yum clean metadata
yum install -y zfs

# packages install
yum -y install p7zip bzip2 emacs-nox tmux mercurial git expect tree GraphicsMagick htop \
    telnet nmap tcpdump net-tools ethtool ipv6calc \
    tigervnc-server tigervnc xterm terminator firefox thunderbird elinks \
    WindowMaker compiz-lxde \
    yum-plugin-versionlock
# mate - source: https://www.rootusers.com/how-to-install-mate-gui-in-centos-7-linux/
yum groupinstall -y "Server with GUI"
yum groupinstall -y "MATE Desktop"
yum groupinstall -y "Development and Creative Workstation"
yum groupinstall -y "Platform Development"
yum groupinstall -y "Additional Development"
yum groupinstall -y "Java Platform"
# better instructions to install libreoffice: https://www.if-not-true-then-false.com/2012/install-libreoffice-on-fedora-centos-red-hat-rhel/
#yum groupinstall -y "Office Suite and Productivity"

# Oracle VirtualBox - source: https://www.itzgeek.com/how-tos/linux/centos-how-tos/install-virtualbox-4-3-on-centos-7-rhel-7.html
#wget -q https://www.virtualbox.org/download/oracle_vbox.asc
#rpm --import oracle_vbox.asc
#rm oracle_vbox.asc
#wget http://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo -O /etc/yum.repos.d/virtualbox.repo
#yum install VirtualBox-6.0

# enables sshd port forwarding
[[ ! -f /etc/ssh/sshd_config.orig ]] && cp /etc/ssh/sshd_config /etc/ssh/sshd_config.orig || true
if grep GatewayPorts /etc/ssh/sshd_config >/dev/null 2>&1; then
    echo 'GatewayPorts yes' >> /etc/ssh/sshd_config
    systemctl restart sshd
fi

