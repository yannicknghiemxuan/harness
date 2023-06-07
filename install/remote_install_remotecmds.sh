#!/usr/bin/env bash
set -euxo pipefail
targetcmd=$1


identify_machine()
{
    is_raspberrypi=false
    if grep 'Raspberry Pi' /proc/cpuinfo >/dev/null 2>&1; then
	is_raspberrypi=true
    fi
}


expand_rootfs()
{
    if [[ $is_raspberrypi == true ]] && [[ $ID == rocky ]]; then
	sudo rootfs-expand || true
    fi
}


add_passwordless_sudoer()
{
    if [[ $OS_TYPE == Linux ]]; then
	sudo bash -c "echo \"$1 ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/$1"
	sudo chown root:root "/etc/sudoers.d/$1"
	sudo chmod 440 "/etc/sudoers.d/$1"
    fi
}


prepare_auto()
{
    sudo mkdir /auto || true
    sudo chown root:$admingroup /auto
    cat > /var/tmp/autoenv <<EOF
# === Mac OS ===
# export AUTOROOT=/Users/auto
# === Linux / Unix ===
export AUTOROOT=/auto

# === server on local network ===
export SERVERURL=cygnus
export SERVERPORT=22
# === server on remote network ===
# export SERVERURL=www.irishgalaxy.com
# export SERVERPORT=8081

# === machines details and settings ===
export ISGALAXY=true
export ISTHEPROJ=false
EOF
    sudo mv /var/tmp/autoenv /etc
    sudo chown root /etc/autoenv
    sudo chmod 664 /etc/autoenv
}


prepare_hosts()
{
    if [[ ! -d /etc/hosts_orig ]]; then
	sudo cp /etc/hosts /etc/hosts_orig
	sudo bash -c 'echo "17.17.0.1 	cygnus" >> /etc/hosts'
    fi
}


configure_fstab()
{
    if [[ $is_raspberrypi == false ]]; then
	return
    fi
    if  [[ $ID == ubuntu ]] || [[ $ID == rocky ]]; then
	if [[ ! -f /etc/fstab_orig ]]; then
	    sudo cp /etc/fstab /etc/fstab_orig
	fi
	egrep -v /boot /etc/fstab > /var/tmp/fstab
	echo "/dev/mmcblk0p1  /boot vfat    defaults,noatime 0 0" >> /var/tmp/fstab
	sudo mv /var/tmp/fstab /etc
	sudo umount /boot
	sudo mount /boot
    fi
}


configure_networking()
{
    . /var/tmp/networkinfo.sh
    if [[ $is_raspberrypi == true ]] && [[ $ID == rocky ]]; then
	sudo /var/tmp/harness/setup/raspberry-pi/configure_rocky_network.sh "$host" "$ip"
    fi
}


prepare_tnx_account()
{
    sudo useradd tnx -G $admingroup || true
    add_passwordless_sudoer tnx
    sudo mkdir /home/tnx/.ssh || true
    sudo chown tnx:tnx /home/tnx/.ssh
    sudo cp /var/tmp/id_rsa /var/tmp/id_rsa.pub /var/tmp/authorized_keys /home/tnx/.ssh
    sudo chmod 600 /home/tnx/.ssh/id_rsa
    sudo chmod 644 /home/tnx/.ssh/{authorized_keys,id_rsa.pub}
    sudo chown -R tnx:tnx /home/tnx/.ssh
    sudo bash -c "echo ""'""export PATH=/auto/harness/bin:$PATH""'"" >> /home/tnx/.bashrc"
}


step_1()
{
    sudo chown -R ansible:$admingroup /var/tmp/*.sh /var/tmp/harness
    if [[ $ID == rocky ]]; then
	add_passwordless_sudoer rocky
    fi
    expand_rootfs
    prepare_auto
    prepare_hosts
    configure_fstab
    configure_networking
    prepare_tnx_account
}


install_harness()
{
    case $ID in
	rocky)
	    sudo dnf upgrade -y
	    ;;
	ubuntu)
	    sudo apt-get update
	    sudo apt-get dist-upgrade -y
	    sudo snap refresh
	    ;;
    esac
    remoteuser=tnx sudo -u tnx /var/tmp/harness/install/install.sh
}


cleanup_install()
{
    sudo rm -rf /var/tmp/id_rsa \
       /var/tmp/id_rsa.pub \
       /var/tmp/networkinfo.sh \
       /var/tmp/remote_install_remotecmds.sh \
       /var/tmp/harness
}


step_2()
{
    install_harness
    cleanup_install
}


main()
{
    . /var/tmp/harness/modules/identify_OS
    identify_machine
    case $targetcmd in
	step_1)
	    step_1
	    ;;
	step_2)
	    step_2
	    ;;
	reboot)
	    sudo reboot
	    ;;
    esac
}


main
