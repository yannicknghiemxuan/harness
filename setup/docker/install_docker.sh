#!/usr/bin/env bash
set -euxo pipefail
# documentation:
# - https://docs.docker.com/engine/install/ubuntu/
# - https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
. /etc/os-release


apt_install_docker()
{
    sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
    sudo apt-get update
    sudo apt-get -y install \
	 apt-transport-https \
	 ca-certificates \
	 curl \
	 gnupg-agent \
	 software-properties-common
    # adding dockers GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
	| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    # setting up the repo
    echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
	| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl enable docker --now
    sudo usermod -aG docker ansible || true
    sudo usermod -aG docker $USER || true
}


apt_install_nvidiadocker()
{
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update
    sudo apt -y install nvidia-container-toolkit
    sudo systemctl restart docker
}


case $ID in
    centos|rocky)
	echo "use podman on RH based systems"
	exit 1
	;;
    linuxmint|ubuntu)
	apt_install_docker
	if sudo hwinfo --gfxcard| grep 'nvidia_drm is active' >/dev/null 2>&1; then
	    apt_install_nvidiadocker
	fi
esac
