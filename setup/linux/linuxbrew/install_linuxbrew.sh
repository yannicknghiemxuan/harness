#!/usr/bin/env bash
# source: https://www.tecmint.com/linuxbrew-package-manager-for-linux/
set -euxo pipefail
. /etc/autoenv
[[ ${SOURCED_IDENTIFY_OS-} != yes ]] && . $AUTOROOT/harness/modules/identify_OS || true

case "$ID" in
    ubuntu|linuxmint)
	export DEBIAN_FRONTEND=noninteractive
	sudo apt-get update \
	    && sudo apt-get install -y build-essential curl file git
	;;
    centos|rocky)
	sudo dnf groupinstall -y 'Development Tools' \
	    && sudo dnf install -y curl file git
	;;
    *)
	echo "error: unknown OS ID $ID"
	exit 1
	;;
esac
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
if ! grep linuxbrew ~/.bashrc; then
    echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin/:$PATH"' >> ~/.bashrc
    echo 'export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"' >> ~/.bashrc
    echo 'export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"' >> ~/.bashrc
fi
