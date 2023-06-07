#!/usr/bin/env bash
set -euxo pipefail
sudo apt-get update && sudo apt-get install -yqq pinentry-tty
# showing choices: update-alternatives --display pinentry
sudo update-alternatives --set pinentry /usr/bin/pinentry-curses
