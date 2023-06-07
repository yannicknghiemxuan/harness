#!/usr/bin/env bash
# source:
# - https://www.imore.com/how-open-apps-anywhere-macos-catalina-and-mojave
set -euxo pipefail
sudo spctl --master-disable
echo "you can type sudo spctl --master-enable to revert this action"
