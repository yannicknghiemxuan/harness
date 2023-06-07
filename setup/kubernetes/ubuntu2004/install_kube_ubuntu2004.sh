#!/usr/bin/env bash
set euxo pipefail
# sources:
# - https://microk8s.io/docs/ : microk8s quick start guide
# - https://microk8s.io/docs/registry-images : docker images management with microk8s

# to show avaible versions: snap info microk8s
k8sver=1.15/stable

# installs docker in order to be able to build images to push to k8s
#sudo apt update && apt install docker.io
#sudo usermod -aG docker ${USER}
# installs kubernetes using snap
sudo snap install microk8s --classic --channel=${k8sver}
# usually using microk8s kubectl alias should but kubectl is sometimes needed by for example kadalu
sudo snap install kubectl --classic --channel=${k8sver}
sudo usermod -a -G microk8s ${USER}
sudo chown -f -R $USER ~/.kube
microk8s status --wait-ready
mkdir -p ~/.kube || true
microk8s.config -l > ~/.kube/config > $HOME/.kube/config
# recommended by microk8s inspect
sudo apt install -y iptables-persistent
sudo iptables -P FORWARD ACCEPT

# allows privileged containers for kadalu (mandatory)
# source: https://gist.github.com/antonfisher/d4cb83ff204b196058d79f513fd135a6
# doc: https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/
if ! grep -E '--allow-privileged=true' /var/snap/microk8s/current/args/kube-apiserver >/dev/null 2>&1; then
  sudo bash -c 'echo "--allow-privileged=true" >> /var/snap/microk8s/current/args/kube-apiserver'
  microk8s stop
  microk8s start
  microk8s status --wait-ready
fi
# another hack for kadalu to work properly
sudo mkdir -p /var/lib/kubelet/pods || true
sudo chmod 750 /var/lib/kubelet/pods

# installs the addons
microk8s enable dns
microk8s enable registry
microk8s enable metaldb
microk8s enable storage


# to load a docker image
# microk8s ctr image import <image>
# to list the docker images installed
# microk8s ctr images ls

# to reset the full config of microk8s
# microk8s reset

# to check the config
# microk8s inspect

# to uninstall and clean any trace
# microk8s.reset && sudo snap remove microk8s