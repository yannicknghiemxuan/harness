#!/usr/bin/env bash
# installs glusterfs
# sources:
# - https://medium.com/searce/glusterfs-dynamic-provisioning-using-heketi-as-external-storage-with-gke-bd9af17434e5
# - https://kifarunix.com/install-and-setup-glusterfs-on-ubuntu-18-04/
set -x
hostname=$(uname -n)
. /etc/os-release

# loads the configuration file
. /gluster_env

install_packages()
{
    # note: lvm is actually needed by heketi
    case $ID in
	centos)
	    yum update -y
	    yum install -y centos-release-gluster glusterfs-server lvm2
	    yum versionlock centos-release-gluster glusterfs-server
	;;
	ubuntu)
	    apt-get update && apt-get dist-upgrade -y
	    apt-get install -y software-properties-common
	    add-apt-repository ppa:gluster/glusterfs-6
	    apt-get update
	    apt install -y glusterfs-server glusterfs-client lvm2
	    apt-mark hold glusterfs-server glusterfs-client
	;;
    esac
    systemctl enable --now glusterd
}


configure_firewall()
{
    firewall-cmd --zone=public --add-port=24007-24008/tcp --permanent
    firewall-cmd --zone=public --add-port=24009/tcp --permanent
    firewall-cmd --zone=public --add-service=nfs --add-service=samba --add-service=samba-client --permanent
    firewall-cmd --zone=public --add-port=111/tcp --add-port=139/tcp --add-port=445/tcp \
		 --add-port=965/tcp --add-port=2049/tcp --add-port=38465-38469/tcp \
		 --add-port=631/tcp --add-port=111/udp --add-port=963/udp \
		 --add-port=49152-49251/tcp --permanent
    firewall-cmd --reload
}


probe_nodes()
{
    echo "gluster nodes probing, press a key when all the nodes have the gluster packages installed and the services up"
    read
    for i in $myglusternodes; do
	[[ $i == $hostname ]] && continue
	echo "connecting to $i"
	gluster peer probe $i
    done
    echo "list of gluster peers:"
    gluster peer status
    gluster pool list
}


install_packages
#configure_firewall
