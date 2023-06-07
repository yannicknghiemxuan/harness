#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
[[ ${SOURCED_IDENTIFY_OS-} != yes ]] && . $AUTOROOT/harness/modules/identify_OS || true
srcdir=/zdata/repo/install/games/doom/
targetdir=$HOME/games/doomwad
gzdoomver=4.10.0
gzdoomdeburl=https://github.com/coelckers/gzdoom/releases/download/g${gzdoomver}/gzdoom_${gzdoomver}_amd64.deb


install_game_data()
{
    if [[ ! -d $targetdir ]]; then
	mkdir -p "$targetdir"
	rsync -ave "ssh -p $SERVERPORT" \
	      --progress "$SERVERURL:$srcdir" \
	      "$targetdir"
	cd "$targetdir"
	for i in *.7z; do
	    7z x "$i"
	    rm "$i"
	done
	cd -
    fi
}


install_zandronum()
{
    if command -v zandronum >/dev/null 2>&1; then
	return
    fi
    sudo apt-add-repository 'deb http://debian.drdteam.org/ stable multiverse'
    wget -O - http://debian.drdteam.org/drdteam.gpg | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install -y zandronum
}


install_gzdoom()
{
    if command -v gzdoom >/dev/null 2>&1; then
	return
    fi
    payloadurl=$gzdoomdeburl
    download_install_deb
}


download_install_deb()
{
    tmpdir=$(mktemp -d)
    cd "$tmpdir"
    payloadfile=$(echo $payloadurl | awk -F/ '{print $NF}')
    wget "$payloadurl"
    sudo dpkg -i "$payloadfile"
    cd -
    rm -rf "$tmpdir"
}


main()
{
    case $ID in
	debian|ubuntu|linuxmint)
	    case $OS_ARCH in
		i686)
		    install_zandronum
		    ;;
		x86_64)
		    install_gzdoom
		    ;;
	    esac
	    ;;
	centos|rocky)
	    ;;
	macos)
	    ;;
	freebsd)
	    ;;
    esac
    install_game_data
}


main
