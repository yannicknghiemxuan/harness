#!/usr/bin/zsh
[[ ! -d /minecraft_server ]] && exit 0
/usr/bin/rsync -av --delete /minecraft_server /galaxy/home/tnx/
