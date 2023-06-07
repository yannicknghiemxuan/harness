#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
host=$(hostname | awk -F\. '{print $1}')
os=$(uname -s)
[[ ! -d ~/.password-store/machines/ssh-keys ]] && exit 1 || true
# installs the private key
mkdir -p ~/.ssh || true
chmod 700 ~/.ssh
gpg --decrypt ~/.password-store/machines/ssh-keys/"${host}_${USER}".gpg > ~/.ssh/identity
cp -a ~/.ssh/identity ~/.ssh/id_rsa
cp -a "$AUTOROOT/rigs/galaxy/sshpub/${host}_${USER}".pub ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/identity ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
chown -R "$USER:$USER" ~/.ssh
