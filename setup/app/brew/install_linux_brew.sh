#!/usr/bin/env bash
# source: https://docs.brew.sh/Homebrew-on-Linux
set -euxo pipefail
. /etc/autoenv
[[ ${SOURCED_IDENTIFY_OS-} != yes ]] && . $AUTOROOT/harness/modules/identify_OS || true
targetdir=/home/linuxbrew
owneruser=root
case $ID_LIKE in
    *debian*|*ubuntu*)
	ownergroup="sudo"
	sudo apt-get install -y build-essential procps curl file git
	;;
    *rhel*)
	ownergroup="wheel"
	sudo dnf -y groupinstall 'Development Tools'
	sudo dnf -y install procps-ng curl file git
	;;
    *)
	echo "error: do not know what to do for this OS"
	exit 1
	;;
esac
sudo mkdir -p "$targetdir/.linuxbrew/bin" || true
sudo chown -R $owneruser "$targetdir"
sudo chgrp -R $ownergroup "$targetdir"
sudo chmod -R 2775 "$targetdir"
git clone https://github.com/Homebrew/brew "$targetdir/.linuxbrew/Homebrew"
sudo ln -s "$targetdir/.linuxbrew/Homebrew/bin/brew" "$targetdir/.linuxbrew/bin"
eval $("$targetdir/.linuxbrew/bin/brew" shellenv)
