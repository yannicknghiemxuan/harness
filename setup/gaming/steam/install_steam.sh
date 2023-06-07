#!/usr/bin/env bash
set -euxo pipefail
sudo add-apt-repository multiverse
sudo apt-get update
sudo apt install -y steam
