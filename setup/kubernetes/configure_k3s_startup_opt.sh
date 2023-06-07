#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
svcfile=/etc/systemd/system/k3s.service

[[ ! -f ${svcfile}_orig ]] && sudo cp $svcfile ${svcfile}_orig || true
sudo cp ${svcfile}_orig $svcfile
exit 0
sudo sed -i -e "s@k3s server --docker@k3s server --docker --kube-apiserver-arg audit-policy-file=$AUTOROOT/harness/config/k3s/audit-policy.yaml \
--kube-apiserver-arg audit-log-path=/var/log/k3s-audit.log@" /etc/systemd/system/k3s.service
