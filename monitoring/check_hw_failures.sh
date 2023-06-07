#!/usr/bin/env bash
# checks for any hardware failure detected by rasdaemon
set -euxo pipefail
. /etc/autoenv
[[ ${SOURCED_NOTIFY-} != yes ]] && . $AUTOROOT/harness/modules/notify || true
tmpfile=/tmp/check_hw_failures.$$

if ! systemctl is-active --quiet rasdaemon.service; then
    send_notif \
	HARDWARE_MONITORING \
	"rasdaemon.service is not active"
    exit 1
fi
if ! systemctl is-active --quiet ras-mc-ctl.service; then
    send_notif \
	HARDWARE_MONITORING \
	"ras-mc-ctl.service is not active"
    exit 1
fi
sudo ras-mc-ctl --summary \
    | grep -v -E '^$|No Memory errors.|No PCIe AER errors.|No Extlog errors.|No MCE errors.' \
	    > $tmpfile 2>/dev/null || true
if [[ ! -s $tmpfile ]]; then
    rm $tmpfile
    exit 0
fi
send_notif_and_file \
    HARDWARE_FAILURE \
    $tmpfile \
    "Potential hardware issues have been detected by rasdaemon."
