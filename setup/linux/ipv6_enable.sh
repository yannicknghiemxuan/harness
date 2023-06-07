#!/usr/bin/env bash
# source:
# - https://support.nordvpn.com/Connectivity/Linux/1047409212/How-to-disable-IPv6-on-Linux.htm
set -euxo pipefail
. /etc/os-release
case $ID in
    rocky|redhat|fedora|centos)
	sysctl -w net.ipv6.conf.all.disable_ipv6=0
	sysctl -w net.ipv6.conf.default.disable_ipv6=0
	sysctl -w net.ipv6.conf.tun0.disable_ipv6=0
	sysctl -p
	;;
esac
