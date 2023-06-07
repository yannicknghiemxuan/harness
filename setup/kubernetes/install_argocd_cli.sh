#!/usr/bin/env bash
set -euxo pipefail

brew install \
     argoproj/tap/kubectl-argo-rollouts \
     argocd
