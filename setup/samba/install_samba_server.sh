#!/usr/bin/env bash
set -euxo pipefail
# documentation:
# - https://www.tecmint.com/install-samba-rhel-rocky-linux-and-almalinux/
# - https://www.tecmint.com/setup-samba-file-sharing-for-linux-windows-clients/
. /etc/autoenv
. /etc/os-release

case $ID in
    centos|rocky)
	sudo dnf install -y samba samba-common samba-client
	sudo setsebool -P samba_export_all_ro=1 samba_export_all_rw=1
	sudo firewall-cmd --permanent --add-service=samba
	sudo firewall-cmd --reload
	;;
    linuxmint|ubuntu)
	;;
esac
if [[ ! -f /etc/samba/smb.conf_orig ]]; then
    sudo cp -a /etc/samba/smb.conf /etc/samba/smb.conf_orig
fi
sudo cp $AUTOROOT/rigs/*/config/$(uname -n)/smb.conf /etc/samba/smb.conf
sudo systemctl enable --now smb
sudo systemctl enable --now nmb
sudo groupadd galaxy || true
