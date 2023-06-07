#!/usr/bin/env bash
set -auxo pipefail
basearch=x86_64
centosver=7.6.1810
centosmver=7
basedir=/home/tnx/dontsave/openstack/repomirror

mkcd() {
    [[ -z $1 ]] && exit 1
    [[ ! -d $1 ]] && mkdir -p $1
    cd $1
}


# RDO repo
for couple in \
    $basedir/rdo/current-passed-ci@rsync://trunk.rdoproject.org/centos7-queens/current-passed-ci/ \
    $basedir/rdo/kvm-common@rsync://mirror.centos.org/centos/7/virt/$basearch/kvm-common/ \
    $basedir/rdo/openstack-queens@rsync://mirror.centos.org/centos/7/cloud/$basearch/openstack-queens/ \
    ; do
    targetdir=$(echo $couple | awk -F@ '{print $1}')
    baseurl=$(echo $couple | awk -F@ '{print $2}')
    mkcd $targetdir
    rsync -avSHP --delete --exclude "local*" --exclude "isos" $baseurl $PWD
done
exit

# CentOS repo
targetdir=$basedir/centos
mkcd $targetdir
[[ ! -d $centosver ]] && mkdir $centosver
[[ ! -h $centosmver ]] && ln -s $centosver $centosmver
baseurl=rsync://ftp.heanet.ie/pub/centos/$centosver/
rsync -avSHP --delete --exclude "local*" --exclude "isos" $baseurl $centosver
