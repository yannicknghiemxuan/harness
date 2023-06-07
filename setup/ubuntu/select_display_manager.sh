#!/usr/bin/env bash
set -euxo pipefail
sudo dpkg-reconfigure $1

# set_dm() {
#     DISPLAY_MANAGER=$1
#     DISPLAY_MANAGER_SERVICE=/etc/systemd/system/display-manager.service
#     DEFAULT_DISPLAY_MANAGER_FILE=/etc/X11/default-display-manager
#     DISPLAY_MANAGER_BIN=$(which $DISPLAY_MANAGER)
#     if [[ ! -e "${DISPLAY_MANAGER_BIN}" ]]; then
# 	echo "${DISPLAY_MANAGER} seems not to be a valid display manager or is not installed." >&2
# 	exit 1
#     fi
#     sudo bash -c "echo $DISPLAY_MANAGER_BIN > $DEFAULT_DISPLAY_MANAGER_FILE"
#     sudo bash -c "DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true /usr/sbin/dpkg-reconfigure $DISPLAY_MANAGER"
#     sudo bash -c "echo \"set shared/default-x-display-manager $DISPLAY_MANAGER\" | /usr/bin/debconf-communicate"
#     echo -n "systemd service is set to: "
#     readlink $DISPLAY_MANAGER_SERVICE
#     echo -n "$DEFAULT_DISPLAY_MANAGER_FILE is set to: "
#     cat $DEFAULT_DISPLAY_MANAGER_FILE
#     echo -n "debconf is set to: "
#     sudo bash -c "echo get shared/default-x-display-manager | /usr/bin/debconf-communicate"
# }

# set_dm $1
