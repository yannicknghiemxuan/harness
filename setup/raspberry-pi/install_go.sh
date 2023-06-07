#!/usr/bin/env bash
set -euxo pipefail
gofile=go1.15.linux-arm64.tar.gz
golangcilintver=v1.30.0


install_go()
{
    [[ -d /usr/local/go ]] && return || true
    sudo dnf install -y wget libpng12
    cd $builddir
    wget https://dl.google.com/go/$gofile
    sudo tar -C /usr/local -xzf $gofile
    rm $gofile
}


install_go
go get -u golang.org/x/lint/golint
# installation of /golangci-lint
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin $golangcilintver
