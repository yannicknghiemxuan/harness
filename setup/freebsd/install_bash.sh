#!/bin/sh
set -x
# uncomment for proxy server
http_proxy="http://www-proxy-lon.uk.oracle.com:80"
export http_proxy
ASSUME_ALWAYS_YES=yes
export ASSUME_ALWAYS_YES
pkg install bash
