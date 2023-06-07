#!/usr/bin/env bash
# source: https://docs.openstack.org/project-deploy-guide/kolla-ansible/ocata/quickstart.html
#set -euxo pipefail
set -x
EDITOR=/usr/bin/vi
workdir=$HOME/workspace/openstack
# updates the packages
yum upgrade -y
# Make sure the pip package manager is installed and upgraded to the latest before proceeding
yum install -y epel-release
yum install -y python-pip
pip install -U pip
# Install dependencies needed to build the code with pip package manager
yum install -y python-devel libffi-devel gcc openssl-devel
# Install ansible
yum install -y ansible
# Install docker
curl -sSL https://get.docker.io | bash
# Configures the docker daemon
# Create the drop-in unit directory for docker.service
mkdir -p /etc/systemd/system/docker.service.d
# Create the drop-in unit file
tee /etc/systemd/system/docker.service.d/kolla.conf <<-'EOF'
[Service]
MountFlags=shared
EOF
# Restart Docker
systemctl daemon-reload
systemctl restart docker
# The old docker-python is obsoleted by python-docker-py
yum install -y python-docker-py
# install, start, and enable ntp
yum install -y ntp
systemctl enable ntpd.service
systemctl start ntpd.service
# Libvirt is started by default on many operating systems. Disable libvirt on
# any machines that will be deployment targets. Only one copy of libvirt may 
# be running at a time.
systemctl stop libvirtd.service
systemctl disable libvirtd.service
# Install kolla-ansible and its dependencies using pip
pip install kolla-ansible
# Copy the configuration files globals.yml and passwords.yml to /etc
cp -r /usr/share/kolla/etc_examples/kolla /etc/kolla/
# creation of a work directory
mkdir -p $workdir
cd $workdir
# Clone the Kolla and Kolla-Ansible repositories from git
yum install -y git
[[ ! -d kolla ]] && \
    git clone https://github.com/openstack/kolla
[[ ! -d kolla-ansible ]] && \
    git clone https://github.com/openstack/kolla-ansible
# Copy the configuration files to /etc directory
cp -r kolla-ansible/etc/kolla /etc/kolla/
# Copy the configuration files to the current directory
cp kolla-ansible/ansible/inventory/* .
# TODO configure a local registry https://docs.openstack.org/project-deploy-guide/kolla-ansible/ocata/multinode.html
# configures globals.yml
[[ ! -f /etc/kolla/globals.yml_orig ]] && \
    cp /etc/kolla/globals.yml /etc/kolla/globals.yml_orig
cat <<EOF
now an editor will open /etc/kolla/globals.yml, configure the net interfaces, ie:
network_interface: "ens3"
neutron_external_interface: "ens4"
EOF
read
$EDITOR /etc/kolla/globals.yml
# Generate passwords to /etc/kolla/passwords.yml
./kolla-ansible/tools/generate_passwords.py
# Build container images
# edit the file /etc/systemd/system/docker.service.d/kolla.conf to include the
# MTU size to be used for Docker containers (this step is only needed if the
# MTU allowed on the nic is different than 1500)
# if [[ ! -f /etc/systemd/system/docker.service.d/kolla.conf_orig ]]; then
#     cp /etc/systemd/system/docker.service.d/kolla.conf \
#         /etc/systemd/system/docker.service.d/kolla.conf_orig
# cat >> /etc/systemd/system/docker.service.d/kolla.conf << EOF
# ExecStart=
# ExecStart=/usr/bin/docker daemon \
#  -H fd:// \
#  --mtu 1400
# EOF
# Restart Docker
systemctl daemon-reload
systemctl restart docker
### PROBLEM: after this, the docker service hangs at startup
