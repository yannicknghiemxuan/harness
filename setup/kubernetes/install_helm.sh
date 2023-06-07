#!/usr/bin/env bash
set -euxo pipefail
helmver=v3.3.1

install_on_Linux()
{
    if [[ ! -x /usr/local/bin/helm ]]; then
	tmpdir=/tmp/helmsetup.$$
	mkdir -p $tmpdir || true
	cd $tmpdir
	wget "https://get.helm.sh/helm-${helmver}-linux-${arch}.tar.gz"
	tar xvf helm*.tar.gz
	sudo mv */helm /usr/local/bin
	sudo chown root:root /usr/local/bin/helm
	sudo chmod 775 /usr/local/bin/helm
	cd -
	rm -rf $tmpdir
    fi
}


install_on_MacOS()
{
    # not easy here to get a specific version
    brew install helm
}


case $(uname -m) in
    x86_64)
	arch=amd64
	;;
    arm*)
	arch=arm
	;;
    aarch64)
	arch=arm64
	;;
esac
case $(uname -s) in
    Linux)
	install_on_Linux
	;;
    Darwin)
	install_on_MacOS
	;;
esac
