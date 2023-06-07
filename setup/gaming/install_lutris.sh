#!/usr/bin/env bash
set -euxo pipefail
sudo add-apt-repository ppa:lutris-team/lutris
sudo apt update
sudo apt install -y lutris libopusfile0
