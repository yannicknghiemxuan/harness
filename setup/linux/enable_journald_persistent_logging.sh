#!/usr/bin/env bash
# sources
# - https://www.golinuxcloud.com/enable-persistent-logging-in-systemd-journald/
# - 
set -euxo pipefail
. /etc/autoenv
. $AUTOROOT/harness/modules/identify_OS

if [[ ! -f /etc/systemd/journald.conf_orig ]]; then
    sudo cp -a /etc/systemd/journald.conf /etc/systemd/journald.conf_orig
fi
if [[ $OS_TYPE != Linux ]]; then
   exit 1
fi

case $ID_LIKE in
    *rhel*|*debian*|*ubuntu*)
	sudo bash -c "sed -i 's/#Storage.*/Storage=persistent/' /etc/systemd/journald.conf"
	sudo mkdir /var/log/journal || true
	sudo systemd-tmpfiles --create --prefix /var/log/journal
	# With the restart of service you will loose all the logging of the current session.
	# Hence it is recommended to use killall command below instead of
	# systemctl restart systemd-journald
	sudo killall -USR1 systemd-journald
	sleep 3
	journalctl --verify
    ;;
    *)
	echo "unidentified flavour of Linux"
	exit 1
    ;;
esac
