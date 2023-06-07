#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
os=$(uname -s)
targetuser=$USER
[[ $USER == root ]] && targetuser=tnx || true
# update the authorized_keys from the public keys for all the machines
sudo -u $targetuser bash -c "mkdir -p ~/.ssh" || true
sudo -u $targetuser bash -c "chmod 700 ~/.ssh"
sudo -u $targetuser bash -c "cat $AUTOROOT/rigs/*/sshpub/*.pub | sort -u > ~/.ssh/authorized_keys"
sudo -u $targetuser bash -c "chmod 600 ~/.ssh/authorized_keys"
case $os in
    Linux)
	GROUP=tnx
	;;
    Darwin)
	GROUP=staff
	;;
esac
sudo -u $targetuser bash -c "chown -R $targetuser ~/.ssh"
sudo -u $targetuser bash -c "chgrp -R $GROUP ~/.ssh"
