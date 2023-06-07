#!/usr/bin/env bash
# script to execute on a node
set -euxo pipefail
. /etc/autoenv
. /etc/os-release

# sources:
# - https://github.com/rancher/k3s/issues/401
# - https://www.thegeekdiary.com/how-to-disable-firewalld-and-and-switch-to-iptables-in-centos-rhel-7/
configure_iptables()
{
    sudo systemctl disable --now firewalld || true
    sudo systemctl enable --now iptables
    sudo iptables -L
    # Clearing leftover firewalld rules
    sudo iptables -t nat -F
    sudo iptables -t mangle -F
    sudo iptables -F
    sudo iptables -X
    case $ID in
	centos)
	    sudo service iptables save
	    ;;
	ubuntu|linuxmint)
	    sudo netfilter-persistent save
	    ;;
    esac
    sudo iptables -L
}


install_packages()
{
    case $ID in
	rocky|centos)
	    sudo dnf install -y lvm2 iptables-services python3 \
		 gdisk podman
	    ;;
	ubuntu|linuxmint)
	    sudo apt-get update
	    sudo apt-get install -y lvm2 iptables iptables-persistent python3 \
		 gdisk podman
	    ;;
    esac
    sudo ln -s $(which python3) /usr/bin/python || true
}


install_packages
configure_iptables
