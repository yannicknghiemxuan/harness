#!/usr/bin/env bash
set -x
condadir=/opt/anaconda3
downdir=/opt/anaconda_download
archname=Anaconda3-2020.07-Linux-x86_64.sh

[[ -f $condadir ]] && exit
sudo mkdir -p $downdir
sudo chown tnx:tnx $downdir
cd $downdir
[[ ! -f $archname ]] && wget "https://repo.continuum.io/archive/$archname"
sudo bash ./$archname -b -p $condadir
[[ $? -ne 0 ]] && exit
sudo chown -R tnx:tnx $condadir
# adding anaconda to path
cat >> ~/.bashrc << EOF
export PATH="$condadir/bin:\$PATH"
EOF
export PATH="$condadir/bin:$PATH"
# updates anaconda, have to do it twice
conda update conda -y
conda update conda -y
# installs the documentation files on the local disk
#conda install continuum-docs -y

# configures the shell for anaconda
conda init bash

# this is for keras
conda create -y -n py38 python=3.8 anaconda
