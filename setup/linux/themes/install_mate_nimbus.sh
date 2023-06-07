#!/usr/bin/env bash
set -euxo pipefail
tmpdir=$(mktemp -d)
cd $tmpdir
scp cygnus:/zdata/repo/themes/mate/nimbus-pack.7z .
7z x nimbus-pack.7z
chmod -R u+w .themes .icons .mate-panel
cp -a .themes .icons .mate-panel ~/
cd -
rm -rf $tmpdir
mate-appearance-properties >/dev/null 2>&1

