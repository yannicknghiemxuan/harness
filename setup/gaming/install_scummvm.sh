#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
[[ ${SOURCED_IDENTIFY_OS-} != yes ]] && . $AUTOROOT/harness/modules/identify_OS || true
srcdir=/zdata/repo/install/games/scummvm
targetdir=$HOME/games/scummvm

install_data()
{
    if [[ ! -d $targetdir ]]; then
	mkdir -p "$targetdir"
	rsync -ave "ssh -p $SERVERPORT" \
	      --progress "$SERVERURL:$srcdir/" \
	      "$targetdir"
	cd "$targetdir"
	for i in *.7z; do
	    7z x "$i"
	    rm "$i"
	done
    fi
}


main()
{
    case $ID in
	debian|ubuntu|linuxmint)
	    sudo apt-get update
	    sudo apt-get install -y scummvm
	    ;;
	centos|rocky)
	    ;;
	macos)
	    ;;
	freebsd)
	    ;;
    esac
    install_data
}


main
