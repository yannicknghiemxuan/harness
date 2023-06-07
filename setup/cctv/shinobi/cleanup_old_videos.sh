#!/usr/bin/env bash
set -euxo pipefail
sudo find /shinobi/videos -mtime +14 -name '*.mp4' -print -delete
