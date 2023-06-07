#!/usr/bin/env bash
#set -x
# Yannick NGHIEM-XUAN
# creation    : 17/07/2018   
#
# version / description:
scriptver=05_12_2018
scriptdesc="installs nVidia TensorRT"

tensorrtver=50

# loads the required environment variables and functions
needworkdir=true   # this script needs a work directory
for f in $(cat ~/.theproj)/auto/{.env,.log,.repo}; do [[ ! -f $f ]] && exit 1; source $f; done

checklog=$logdir/checks.log

install_tensorrt()
{
    check_step_completion ${FUNCNAME[0]} || return
    print_step "downloading tensorrt $tensorrtver from the repo"
    download_repo_files tensorrt$tensorrtver
    tensorrtdir=$localrepodir/$remotepath
    print_log "installing tensorrt files"
    sudo dpkg -i $tensorrtdir/nv-tensorrt-repo-ubuntu1604-cuda*_amd64.deb
    [[ $? -ne 0 ]] && exit
    sudo apt-get update
    [[ $? -ne 0 ]] && exit
    sudo apt-get install -y --no-install-recommends \
	 tensorrt \
	 python3-libnvinfer python3-libnvinfer-dev python3-libnvinfer-doc \
	 uff-converter-tf
    [[ $? -ne 0 ]] && exit
    flag_step_completion ${FUNCNAME[0]}
    print_log "now you need to manually reboot and start the script again to continue on the next steps"
    exit
}

check_install_env()
{
    print_log "checking installed TensorRT packagest"
    dpkg -l | grep TensorRT >> $checklog
}

log_script_start
install_tensorrt
check_install_env
log_script_end
