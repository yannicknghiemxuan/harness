#!/usr/bin/env bash
set -x
cfgf=/galaxy/logic/config/s11u3pkg
[[ ! -f $cfgf ]] && exit 1
pkg install --accept $(xargs < $cfgf)
