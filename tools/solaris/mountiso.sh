#!/usr/bin/env bash
set -euxo pipefail
[[ -z $1 ]] && echo "error: missing parameter: <iso_filename>" && exit 1
mount -F hsfs -o ro $(lofiadm -a $1) /galaxy/public_space/tmp
