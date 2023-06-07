#!/usr/bin/env bash
set -euxo pipefail
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get -y install libc6:i386 libasound2:i386 libasound2-data:i386 libasound2-plugins:i386
