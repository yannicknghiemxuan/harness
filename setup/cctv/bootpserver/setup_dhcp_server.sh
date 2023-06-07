#!/usr/bin/env bash
set -euxo pipefail
for fpath in /etc/dhcp/dhcpd.conf /etc/default/isc-dhcp-server; do
    f=$(basename "$fpath")
    if [[ ! -f "${fpath}_orig" ]]; then
	sudo cp "$fpath" "${fpath}_orig"
    fi
    sudo cp "$f" "$fpath"
    sudo chown root:root "$fpath"
done
sudo apt-get update
sudo apt-get install -y isc-dhcp-server
sudo systemctl enable isc-dhcp-server
sudo systemctl stop isc-dhcp-server
sudo systemctl start isc-dhcp-server
echo "now make sure the primary interface is correct in /etc/default/isc-dhcp-server"
echo "and check the logs with journalctl -u isc-dhcp-server -f"
echo "default password for the cameras is admin and no password"
