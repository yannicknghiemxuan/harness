#!/usr/bin/env bash
# source:
# - https://wiki.archlinux.org/title/CPU_frequency_scaling
set -euxo pipefail
kerver=$(uname -a | awk '{print $3}')
sudo apt-get install -y linux-tools-common "linux-tools-$kerver"
# TODO: finish
