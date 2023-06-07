#!/usr/bin/env bash
# documentation:
# - https://kubernetes.io/docs/tasks/tools/install-kubectl/
# stable version:
# - https://dl.k8s.io/release/stable.txt
# available versions:
# - https://kubernetes.io/releases/
set -euxo pipefail
version=$1
tmpdir=/tmp/install_kubectl.$$
mkdir -p $tmpdir
cd $tmpdir
case $(uname -s) in
    Linux)
	osurl=linux
	;;
    Darwin)
	osurl=darwin
	;;
esac
case $(uname -m) in
    x86_64)
	arch=amd64
	;;
    arm*)
	arch=arm
	;;
esac
curl -LO "https://dl.k8s.io/release/v${version}/bin/linux/${arch}/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
sudo chmod 755 /usr/local/bin/kubectl
sudo chown root:root /usr/local/bin/kubectl
cd -
rm -rf $tmpdir
kubectl version --client
