#!/usr/bin/env bash
# source:
# - https://github.com/argoproj/argo-cd/issues/998
set -euxo pipefail
kubectl patch -n argocd secret argocd-secret  -p '{"data": {"admin.password": null, "admin.passwordMtime": null}}'
podname=$(kubectl get pods -n argocd | grep argocd-server | awk '{print $1}')
kubectl delete -n argocd "pod/$podname"
sleep 10
podname=$(kubectl get pods -n argocd | grep argocd-server | awk '{print $1}')
echo "password has been reset to admin / $podname"
