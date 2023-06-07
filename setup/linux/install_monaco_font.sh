#!/usr/bin/env bash
set -euxo pipefail
method=${1-}
MONACO_URL="https://github.com/hbin/top-programming-fonts/raw/master/Monaco-Linux.ttf"

usage()
{
    echo "ERROR: argument expected: user or system" >&2
    exit 1
}

[[ -z ${method-} ]] && usage

case $method in
    user)
	# installation of fonts
	if [[ ! -f ~/.fonts/Monaco-Linux.ttf ]]; then
	    mkdir -p ~/.fonts
	    cd ~/.fonts
	    wget $MONACO_URL
	    fc-cache -fv
	fi
	;;
    system)
	sudo mkdir -p /usr/local/share/fonts || true
	if [[ ! -f /usr/local/share/fonts/Monaco-Linux.ttf ]]; then
	    cd /usr/local/share/fonts
	    sudo wget $MONACO_URL
	    sudo fc-cache -fv
	fi
	;;
    *)
	usage
	;;
esac
