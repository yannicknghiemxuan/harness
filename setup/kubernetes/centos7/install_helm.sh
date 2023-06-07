#!/usr/bin/env bash
# source: https://helm.sh/docs/using_helm/#installing-helm
set -x

sudo yum -y install epel-release
sudo yum -y install snapd
sudo systemctl enable --now snapd.socket
sudo systemctl enable --now snapd
sudo ln -s /var/lib/snapd/snap /snap

snap install helm --classic

# sets the proper permissions for helm
kubectl -n kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller \
   --clusterrole=cluster-admin \
   --serviceaccount=kube-system:tiller

# installs tiler and initializes helm
# you can add --debug to check the generated yaml file passed on to kubectl apply
helm init --history-max 200 --service-account tiller

helm repo update
