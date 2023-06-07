#!/usr/bin/env bash
set -euxo pipefail
yum upgrade -y

yum -y install epel-release

# installing docker - https://docs.docker.com/install/linux/docker-ce/centos/
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
# yum list docker-ce --showduplicates | sort -r	# check
sudo usermod -aG docker tnx
systemctl enable docker.service
systemctl start docker.service
# install docker-compose - https://docs.docker.com/compose/install/
#sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2-rc1/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
chmod 755 /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# opening the ports for docker
# source: https://docs.docker.com/engine/swarm/swarm-tutorial/#open-protocols-and-ports-between-the-hosts
# TCP
firewall-cmd --add-port=2377/tcp --permanent
firewall-cmd --add-port=7946/tcp --permanent
# UDP
firewall-cmd --add-port=7946/udp --permanent
firewall-cmd --add-port=4789/udp --permanent
# not documented but found on the web
firewall-cmd --add-port=2376/tcp --permanent
firewall-cmd --add-port=80/tcp --permanent
# firewall-cmd --list-all # check
firewall-cmd --reload
systemctl restart docker
