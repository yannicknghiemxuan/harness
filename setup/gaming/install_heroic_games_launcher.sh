#!/usr/bin/env bash
set -euxo pipefail
export WINEPREFIX=$HOME/.wine


install_wine()
{
    sudo apt-get install -y wine winetricks
    if [[ ! -d $WINEPREFIX ]]; then
	winetricks
    fi
}


# https://github.com/doitsujin/dxvk/releases
install_dxvk()
{
    cd "$tmpdir"
    payloadurl=https://github.com/doitsujin/dxvk/releases/download/v1.10.2/dxvk-1.10.2.tar.gz
    payloadfile=$(echo $payloadurl | awk -F/ '{print $NF}')
    wget "$payloadurl"
    tar -zxvf "$payloadfile"
    ./dxvk-*/setup_dxvk.sh install
    rm -rf dxvk-*
    cd -
}


install_heroic()
{
    payloadurl=https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.3.9/heroic_2.3.9_amd64.deb
    payloadfile=$(echo $payloadurl | awk -F/ '{print $NF}')
    cd "$tmpdir"
    wget "$payloadurl"
    sudo dpkg -i "$payloadfile"
    sudo apt --fix-broken install -y
    rm "$payloadfile"
    cd -
}


display_postinstall_msg()
{
    set +x
    echo "now go to Settings -> Other and check Use Steam Runtime"
}


main()
{
    tmpdir=$(mktemp -d)
    install_wine
    install_dxvk
    install_heroic
    rm -rf "$tmpdir"
    display_postinstall_msg
}


main
