#!/usr/bin/env bash
# source: https://www.linuxtechi.com/integrate-rhel7-centos7-windows-active-directory/
set -x
yum upgrade -y
yum install -y sssd realmd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients policycoreutils-python

[[ ! -f /etc/resolv.conf_orig ]] && cp /etc/resolv.conf /etc/resolv.conf_orig
tee > /etc/resolv.conf <<EOF
search irishgalaxy.com
nameserver 192.168.0.74
EOF

realm join --user=Administrator irishgalaxy.com
realm list

# checks uid gid of tnx
id tnx@irishgalaxy.com

# making a change so that the domain name does not need to be specified
[[ ! -f /etc/sssd/sssd.conf_orig ]] && cp /etc/sssd/sssd.conf /etc/sssd/sssd.conf_orig
sed -i 's@use_fully_qualified_names = False@use_fully_qualified_names = True@' /etc/sssd/sssd.conf
systemctl restart sssd
systemctl daemon-reload

# to verify
id tnx

