#!/usr/bin/env bash
# expands a partition to occupy the free space on the disk
# inspired from raspi-config
# source: https://github.com/RPi-Distro/raspi-config/blob/master/raspi-config
set -euxo pipefail

do_expand_rootfs() {
  ROOT_PART="$(findmnt / -o source -n)"
  ROOT_DEV="/dev/$(lsblk -no pkname "$ROOT_PART")"

  PART_NUM="$(echo "$ROOT_PART" | grep -o "[[:digit:]]*$")"

  # NOTE: the NOOBS partition layout confuses parted. For now, let's only 
  # agree to work with a sufficiently simple partition layout
  # if [ "$PART_NUM" -ne 2 ]; then
  #   whiptail --msgbox "Your partition layout is not currently supported by this tool. You are probably using NOOBS, in which case your root filesystem is already expanded anyway." 20 60 2
  #   return 0
  # fi

  LAST_PART_NUM=$(parted "$ROOT_DEV" -ms unit s p | tail -n 1 | cut -f 1 -d:)
  if [ $LAST_PART_NUM -ne $PART_NUM ]; then
    whiptail --msgbox "$ROOT_PART is not the last partition. Don't know how to expand" 20 60 2
    return 0
  fi

  # Get the starting offset of the root partition
  PART_START=$(parted "$ROOT_DEV" -ms unit s p | grep "^${PART_NUM}" | cut -f 2 -d: | sed 's/[^0-9]//g')
  [ "$PART_START" ] || return 1
  # Return value will likely be error for fdisk as it fails to reload the
  # partition table because the root fs is mounted
  cat > /tmp/fdisk_responses.$$ <<EOF
p
d
$PART_NUM
n
p
$PART_NUM
$PART_START

y
w
EOF
  cat /tmp/fdisk_responses.$$
  echo "type: fdisk $ROOT_DEV and give the responses above"
  # fdisk "$ROOT_DEV" < /tmp/fdisk_responses.$$
  # rm /tmp/fdisk_responses.$$
  echo "rebooting in 10s"
  echo "after reboot please type: sudo resize2fs $ROOT_PART"
  # sleep 10
  # sudo reboot
}


do_expand_rootfs
