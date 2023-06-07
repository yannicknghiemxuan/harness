#!/usr/bin/env bash
# source:
# - https://linuxmint-user-guide.readthedocs.io/en/latest/upgrade-to-mint-20.html
set -euxo pipefail
echo "{}" | sudo tee /etc/timeshift.json
