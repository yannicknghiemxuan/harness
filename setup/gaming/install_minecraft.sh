#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
[[ ${SOURCED_IDENTIFY_OS-} != yes ]] && . $AUTOROOT/harness/modules/identify_OS || true

if [[ ! -d ~/Desktop/minecraft_mods ]]; then
    scp -r cygnus:/zdata/repo/install/games/minecraft ~/Desktop/minecraft_mods
fi
case $OS_TYPE in
    Linux)
	case $ID in
	    ubuntu)
		sudo apt-get install -y openjdk-17-jre
		sudo snap install mc-installer
		;;
	esac
	;;
    Darwin)
	open ~/Desktop/minecraft_mods
	;;
esac
