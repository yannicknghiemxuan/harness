#!/usr/bin/env bash
# releases page:
# - https://github.com/kubernetes-sigs/kustomize/releases
# inspired from x64 specific script:
# - https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh
set -euxo pipefail
. /etc/autoenv

release_url="https://api.github.com/repos/kubernetes-sigs/kustomize/releases"

. $AUTOROOT/harness/modules/identify_OS
opsys=$OS_TYPE
case $OS_TYPE in
    Darwin)
	group=staff
	;;
    Linux)
	group=root
	opsys=linux
	;;
    *)
	exit 1
	;;
esac
case $OS_ARCH in
    aarch64)
	arch=arm64
    ;;
    x86_64)
	arch=amd64
    ;;
esac
RELEASE_URL=$(curl -s $release_url | \
		  grep browser_download.*${opsys}_${arch} \
		  | cut -d '"' -f 4 \
		  | sort -V \
		  | tail -n 1 \
	   )
cd /tmp
wget $RELEASE_URL -O kustomize.tgz
tar zxvf kustomize.tgz && rm kustomize.tgz
sudo mv kustomize /usr/local/bin
sudo chown root:$group /usr/local/bin/kustomize
sudo chmod 775 /usr/local/bin/kustomize
