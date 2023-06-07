#!/usr/bin/env bash
# source:
# - https://medium.com/macoclock/time-machine-backups-too-slow-5ed1e5e347a4
set -euxo pipefail
sudo sysctl debug.lowpri_throttle_enabled=0
