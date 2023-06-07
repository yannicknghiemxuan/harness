#!/usr/bin/env bash
# configures eraning / CentOS 7 in preparation of RDO OpenStack install
# doc:   https://www.rdoproject.org/install/packstack/
# guide: https://www.youtube.com/watch?v=Udtr1zJhcrw

exit 1 # not meant to be automated yet

# instead of response file (answer.txt), it is possible to use command line options:
# packstack --allinone --provision-demo=n --os-neutron-ovs-bridge-mappings=extnet:br-ex --os-neutron-ovs-bridge-interfaces=br-ex:eth0 --os-neutron-ml2-type-drivers=vxlan,flat
# source: https://www.rdoproject.org/networking/neutron-with-existing-external-network/

### checks the current state of SELinux (must be disabled)
getenforce # check
sestatus # check
# to disable SELinux 
vi /etc/selinux/config # config file. SELINUX=permissive

### network configuration
# needed by RDO
systemctl disable firewalld NetworkManager
systemctl enable network
# nic configuration
vi /etc/sysconfig/network-scripts/ifcfg-enp1s0f0
ifdown enp1s0f0
ifup enp1s0f0
ip addr # check, instead of ifconfig
ip link # check
# hostname
# source: https://support.rackspace.com/how-to/centos-hostname-change/
[[ ! -f /etc/sysconfig/network.orig ]] && \
    cp /etc/sysconfig/network /etc/sysconfig/network.orig
echo 'HOSTNAME=eranin.irishgalaxy.com' >> /etc/sysconfig/network
[[ ! -f /etc/hosts.orig ]] && \
    cp /etc/hosts /etc/hosts.orig
echo '192.168.0.77 eranin.irishgalaxy.com eranin' >> /etc/hosts
hostnamectl set-hostname eranin.irishgalaxy.com
hostname # check

### locale settings
[[ ! -f /etc/environment.orig ]] && \
    cp /etc/environment /etc/environment.orig
cat > /etc/environment << EOF
LANG=en_US.utf-8
LC_ALL=en_US.utf-8
EOF

### enable the console
# source: http://chrisreinking.com/how-to-enable-serial-console-output-in-centos/
[[ ! -f /etc/sysconfig/grub.orig ]] && \
    cp /etc/sysconfig/grub /etc/sysconfig/grub.orig
sed -e 's@quiet@quiet console=ttyS0@' < /etc/sysconfig/grub.orig > /etc/sysconfig/grub
stty -F /dev/ttyS0 speed 9600
grub2-mkconfig -o /boot/grub2/grub.cfg
systemctl start getty@ttyS0

### packages install
yum -y update
yum install -y emacs-nox tmux vim-enhanced rsync nmap bzip2
# DO NOT INSTALL EPEL WITH RDO / OPENSTACK -> conflics

### RDO repository and OpenStack install
# openstack releases:
# https://docs.openstack.org/puppet-openstack-guide/latest/install/releases.html
yum search openstack # check
# stein was not available yet, will have to switch asap as support for rocky stops in 02/2019
sudo yum install -y centos-release-openstack-rocky
sudo yum update -y
sudo yum install -y openstack-packstack
# sudo packstack --allinone -> to install everything
# but we won't so selection from answer file
packstack --gen-answer-file=answer.txt.orig
cp answer.txt.orig answer.txt
vi answer.txt
# you can add --timeout=600 to the packstack command if you hit timeout issues
packstack --answer-file=answer.txt
# if apache is not seen in the services list, you might need to reboot
systemctl --all -t service | grep -i apache # check
# access the dashboard using the ip directly, not sure why it did not work with the hostname (eranin)


# check the content of the following files:
# - keystonerc_admin
# - keystonerc_demo

# make sure that the services are up and running
# source: https://docs.openstack.org/fuel-docs/newton/userdocs/fuel-user-guide/troubleshooting/service-status.html

# starting the openstack cli client
cd $HOME
. keystonerc_admin
openstack
#[root@eranin ~(keystone_admin)]# openstack
#(openstack) image list
#+--------------------------------------+--------+--------+
#| ID                                   | Name   | Status |
#+--------------------------------------+--------+--------+
#| dd1b7b80-8d16-4586-8f54-7fb1bd5b6ddb | cirros | active |
#+--------------------------------------+--------+--------+
#(openstack) image delete ciros

### installing docker support
# now handled by OpenStack Containers service (Magnum)
# source:
# https://github.com/indigo-dc/nova-docker-documentation/blob/master/README.md
# --> (DEPRECATED) OpenStack nova-docker
# https://wiki.openstack.org/wiki/Docker#Installing_Docker_for_OpenStack
# --> official page but a lot of obsolete info
# https://github.com/indigo-dc/nova-docker-documentation/blob/master/docs/install.md
