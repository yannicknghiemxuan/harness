#!/usr/bin/env bash
set -euxo pipefail
# kernel docs for autosuspend:
# https://www.kernel.org/doc/Documentation/usb/power-management.txt
if [[ $(cat /sys/module/usbcore/parameters/autosuspend) -eq -1 ]]; then
    echo "TODO you need to add the usbcore.autosuspend=<n seconds> to the kernel command line"
fi
