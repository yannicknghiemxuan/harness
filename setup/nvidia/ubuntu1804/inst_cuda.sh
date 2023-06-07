#!/usr/bin/env bash
set -euxo pipefail
# Yannick NGHIEM-XUAN
# creation    : 22/05/2018   
#
# version / description:
scriptver=09_04_2020
scriptdesc="installs or updates the nVidia drivers + cuda + cudnn. Version supported: 10.0 10.1 10.1u2"
forcecleanup=false
targetos=ubuntu1804
cudaver=10.0
cudav=$(echo $cudaver | sed -e 's@u.*@@')
cudaverdash=$(echo $cudaver | sed -e 's@\.@-@' -e 's@u.*@@')

# loads the required environment variables and functions
needworkdir=true   # this script needs a work directory
for f in $(cat ~/.theproj)/auto/{.env,.log,.repo}; do [[ ! -f $f ]] && exit 1; source $f; done
checklog=$logdir/checks.log


update_gpg_keys()
{
    print_step "updates the gpg keys"
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
}


cleanup_pkg()
{
    check_step_completion ${FUNCNAME[0]} && return 0
    print_step "removes any previously installed nVidia package"
    # tries to remove cleanly what can be
    pkgtoremove=$(sudo dpkg -l | grep -E -i 'nvidia|cuda|nccl-|libnccl|nv-tensorrt|graphsurgeon-tf|uff-converter-tf|libcublas' \
		  | grep -E '^i' | awk '{print $2}' | xargs)
    if [[ -n $pkgtoremove ]]; then sudo dpkg --purge --force-all $pkgtoremove; fi
    # source: https://askubuntu.com/questions/99651/apt-get-warning-no-support-for-locale-en-us-utf8
    # to avoid Warning: No support for locale: en_IE.utf8
    # Errors were encountered while processing:
    # nvidia-cuda-toolkit
    sudo locale-gen --purge --no-archive
    sudo apt-get -yqq -f autoremove
    # repairs any package error
    sudo dpkg --configure -a
    sudo sudo apt-get -f -yqq install
    # now removes the garbage the package manager did not clean-up
    if [[ $forcecleanup == true ]]; then
	sudo rm -f /etc/apt/sources.list.d/nvidia-docker.list 2>/dev/null
	sudo rm -rf /var/{/var/cuda-repo-,nccl-repo-,nv-tensorrt-repo-}* \
	     /usr/local/cuda-* \
	     /etc/apt/sources.list.d/{cuda-,nccl-,nv-tensorrt-}*.list \
	     /usr/share/doc/{graphsurgeon-tf,nccl-,nv-tensorrt-,uff-}* \
	     /usr/lib/python*/dist-packages/{graphsurgeon,uff}*
	for i in $(sudo cat /var/lib/dpkg/info/{cuda-,nccl,nv-tensorrt,graphsurgeon-tf,uff-converter-tf}*.list | sort -u); do
	    [[ -f $i ]] && sudo rm -f $i
	done
	sudo rm -f /var/lib/dpkg/info/{cuda-,nccl,nv-tensorrt,graphsurgeon-tf,uff-converter-tf}*
    fi
    flag_step_completion ${FUNCNAME[0]}
    print_log "now you need to manually reboot and start the script again to continue on the next steps"
    exit
}


block_nouveau_driver()
{
    # source: https://linuxconfig.org/how-to-disable-nouveau-nvidia-driver-on-ubuntu-18-04-bionic-beaver-linux
    check_step_completion ${FUNCNAME[0]} && return 0
    print_step "black listing the nouveau driver"
    if [[ ! -f /etc/modprobe.d/blacklist-nvidia-nouveau.conf ]]; then
	tee > /tmp/blacklist-nvidia-nouveau.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF
	sudo chown root:root /tmp/blacklist-nvidia-nouveau.conf
	sudo chmod 644 /tmp/blacklist-nvidia-nouveau.conf
	sudo mv /tmp/blacklist-nvidia-nouveau.conf /etc/modprobe.d/blacklist-nvidia-nouveau.conf
	sudo update-initramfs -u
    fi
    flag_step_completion ${FUNCNAME[0]}
}


install_cuda()
{
    check_step_completion ${FUNCNAME[0]} && return 0
    print_step "downloading cuda $cudaver files from the repo"
    download_repo_files cuda$cudaver
    cudadir=$localrepodir/$remotepath
    print_log "installing cuda repository and the updates"
    if [[ -f $cudadir/cuda-${targetos}.pin ]]; then
	sudo cp $cudadir/cuda-${targetos}.pin /etc/apt/preferences.d/cuda-repository-pin-600
    fi
    # the --force-overwrite option is used to bypass the bug documented here:
    # https://devtalk.nvidia.com/default/topic/1048225/issues-after-installing-cuda-10-/
    sudo dpkg -i --force-overwrite $cudadir/cuda-repo-${targetos}-${cudaverdash}-local-${cudaver}.*_amd64.deb
    [[ $? -ne 0 ]] && exit
    print_log "installing cuda repo key"
    sudo apt-key add /var/cuda-repo-${cudaverdash}-local*/7fa2af80.pub
    sudo apt-get update
    # libcupti-dev replaces former cuda-command-line-tools package
    # it took me some time to figure it out!
    print_log "installing cuda files"
    sudo apt-get install -yqq cuda
    # trying to install nvidia-cuda-toolkit instead to avoid the package conflict as suggested here:
    # https://devtalk.nvidia.com/default/topic/1032886/unable-to-properly-install-uninstall-cuda-on-ubuntu-18-04/?offset=6    
    sudo apt-get -o Dpkg::Options::="--force-overwrite" install -yqq nvidia-cuda-toolkit libcupti-dev
    # this is because these packages can be removed during uninstalls and reinstalls on ubuntu
    # as it happened on hyperion (loss of control of keyboard and mouse)
    # source: https://askubuntu.com/questions/1033767/keyboard-not-working-after-update-to-18-04/1033871
    sudo apt-get install -y xserver-xorg-input-all
    flag_step_completion ${FUNCNAME[0]}
    print_log "now you need to manually reboot and start the script again to continue on the next steps"
    exit
}


install_cudnn()
{
    check_step_completion ${FUNCNAME[0]} && return 0
    print_step "downloading cudnn $cudaver from the repo"
    download_repo_files cudnn$cudaver
    cudnndir=$localrepodir/$remotepath
    print_log "installing cudnn files"
    sudo dpkg -i $cudnndir/libcudnn7*cuda${cudav}_amd64.deb
    # cleans up any left over of previous cuda/cudnn version
# disabled the autoremove as it breaks symbolic links like /usr/local/cuda
#    sudo apt-get autoremove -yqq
    flag_step_completion ${FUNCNAME[0]}
    print_log "now you need to manually reboot and start the script again to continue on the next steps"
    exit
}


install_nccl()
{
    check_step_completion ${FUNCNAME[0]} && return 0
    print_step "downloading nccl $cudaver from the repo"
    download_repo_files nccl$cudaver
    nccldir=$localrepodir/$remotepath
    print_log "installing nccl files"
    sudo dpkg -i $nccldir/*.deb
    sudo apt-get update
    flag_step_completion ${FUNCNAME[0]}
}


update_bashrc()
{
    check_step_completion ${FUNCNAME[0]} && return 0
    print_step "updating ~/.bashrc"
    print_log "modifying ~/.bashrc to add cuda entries to the PATH and LD_LIBRARY_PATH environment variables"
    # removes any previous cuda entry from the path
    cp ~/.bashrc ~/.bashrc.back
    grep -v -E '# cuda environment|export PATH=/usr/local/cuda|export LD_LIBRARY_PATH=' ~/.bashrc > ~/.bashrc_ && mv ~/.bashrc_ ~/.bashrc
    # add the following lines to ~/.bashrc    
    cat >> ~/.bashrc <<EOF
# cuda environment variables
export PATH=/usr/local/cuda-${cudav}/bin:\$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-${cudav}/lib64:/usr/local/cuda/extras/CUPTI/lib64:\$LD_LIBRARY_PATH
EOF
    # load the changes in the current shell
    source ~/.bashrc
    flag_step_completion ${FUNCNAME[0]}
}


check_install_env()
{
    print_log "checking cuda environment"
    # checks the environment variable
    print_log '# env | grep -i cuda'
    env | grep -i cuda >> $checklog
    # verification of the driver
    print_log '# cat /proc/driver/nvidia/version'
    cat /proc/driver/nvidia/version >> $checklog
    # check the version of cuda toolkit
    print_log '# nvcc -V'
    nvcc -V >> $checklog
    # to check the driver install
    print_log '# nvidia-smi'
    nvidia-smi >> $checklog
    # testing the dev environment
    print_log "testing cuda dev environment by compiling and running examples"
    [[ ! -d $workdir/cuda-${cudav}_samples ]] && \
    	cp -PRp /usr/local/cuda-${cudav}/samples $workdir/cuda-${cudav}_samples
    cd $workdir/cuda-${cudav}_samples
    if ! check_step_completion cudamake; then
    	make
    	flag_step_completion cudamake
    fi
    print_log "cd $workdir/cuda-${cudav}_samples/bin/x86_64/linux/release && ./scan && ./matrixMul"
    cd $workdir/cuda-${cudav}_samples/bin/x86_64/linux/release
    print_log "scan test"
    ./scan >> $checklog
    print_log "matrixMul test"
    ./matrixMul >> $checklog
}


log_script_start
cleanup_pkg
block_nouveau_driver
update_gpg_keys
install_cuda
install_cudnn
install_nccl
update_bashrc
check_install_env
log_script_end
