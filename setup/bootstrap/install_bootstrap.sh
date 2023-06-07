#!/usr/bin/env bash
# source:
# - https://linuxconfig.org/how-to-automatically-execute-shell-script-at-startup-boot-on-systemd-linux
# - https://unix.stackexchange.com/questions/126009/cause-a-script-to-execute-after-networking-has-started
set -euxo pipefail
. /etc/autoenv
bootscript=/etc/systemd/system/bootstrap.service


check_requirements()
{
    if [[ -f $bootscript ]]; then
	echo "INFO: $bootscript already exists, skipping" >&2
	exit 0
    fi
}


main()
{
    sudo touch $bootscript
    sudo chown $USER $bootscript
    cat >$bootscript <<EOF
[Unit]
# network.target for compatibility with older systems
Wants=network-online.target
After=network.target network-online.target

[Service]
ExecStart=$AUTOROOT/harness/bootstrap/launch_bootstrap.sh

[Install]
WantedBy=default.target
EOF
    sudo chown root:root $bootscript
    sudo chmod 644 $bootscript
    sudo systemctl daemon-reload
    sudo systemctl enable bootstrap.service
}


check_requirements
main
