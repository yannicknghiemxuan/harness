#!/usr/bin/env bash
set -euxo pipefail
# documentation:
# - https://docs.docker.com/engine/install/centos/
# - https://docs.docker.com/engine/install/ubuntu/
. /etc/os-release

case $ID in
    centos|rocky)
	sudo dnf remove -y \
	     docker-ce \
	     docker-ce-cli \
	     containerd.io \
	     docker \
	     docker-client \
	     docker-client-latest \
	     docker-common \
	     docker-latest \
	     docker-latest-logrotate \
	     docker-logrotate \
	     docker-engine || true
	sudo rm -rf /etc/yum.repos.d/docker-ce.repo
	sudo dnf install -y podman buildah || true
	;;
esac
