#!/usr/bin/env bash
# source: https://github.com/Syllo/nvtop
# on ubuntu 18.04, nvtop needs to be installed from source
needworkdir=true   # this script needs a work directory
for f in $(cat ~/.theproj)/auto/{.env,.log,.repo}; do [[ ! -f $f ]] && exit 1; source $f; done
[[ -x /usr/local/bin/nvtop ]] && echo "nvtop is already installed" && exit

[[ ! -f master.zip ]] && wget 'https://github.com/Syllo/nvtop/archive/master.zip'
unzip master.zip
sudo apt install -y cmake libncurses5-dev libncursesw5-dev git
mkdir -p nvtop-master/build
cd nvtop-master/build
cmake ..
[[ $? -ne 0 ]] && exit
make
[[ $? -ne 0 ]] && exit
sudo make install
