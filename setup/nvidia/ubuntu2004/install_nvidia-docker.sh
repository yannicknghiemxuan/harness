#!/usr/bin/env bash
#set -euxo pipefail
# this script doesnt work with options above yet
set -x
# Yannick NGHIEM-XUAN
# creation    : 27/04/2018   
#
# version / description:
scriptver=30_08_2019
scriptdesc="installs the nVidia docker"

# loads the required environment variables and functions
needworkdir=true   # this script needs a work directory
for f in $(cat ~/.theproj)/auto/{.env,.log,.repo}; do [[ ! -f $f ]] && exit 1; source $f; done

checklog=$logdir/checks.log
cudadir=$localrepodir/cudafiles
myuser=$(whoami)
distribution=ubuntu20.04
cudaver=10.2

check_requirements()
{
    [[ -f $checklog ]] && mv $checklog $checklog.old
    echo "todo" | tee $checklog
}


cleanup_pkg()
{
    check_step_completion ${FUNCNAME[0]} && return 0
    print_step "removes any previously installed nVidia package"
    # tries to remove cleanly what can be
    pkgtoremove=$(sudo dpkg -l | grep -E -i 'docker-ce|containerd|nvidia-container-toolkit|nvidia-container-runtime' \
		  | grep -E '^i' | awk '{print $2}' | xargs)
    if [[ -n $pkgtoremove ]]; then sudo dpkg --purge --force-all $pkgtoremove; fi
    sudo apt-get -yqq -f autoremove
    # repairs any package error
    sudo dpkg --configure -a
    sudo sudo apt-get -f -yqq install
    flag_step_completion ${FUNCNAME[0]}
}


install_docker()
{
    check_step_completion ${FUNCNAME[0]} && return
    print_step "installing docker"
    # source: https://docs.docker.com/install/linux/docker-ce/ubuntu/
    print_step "installing dependencies"
    sudo apt-get update
    sudo apt-get install -y \
	 apt-transport-https \
	 ca-certificates \
	 curl \
	 gnupg-agent \
	 software-properties-common
    print_step "adding gpg key and stable repo"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    print_step "installing docker engine"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    print_log "allowing the user $myuser to administrate docker"
    sudo usermod -aG docker $myuser
    flag_step_completion ${FUNCNAME[0]} && return
    groups | grep docker >/dev/null 2>&1
    print_log "now have been added to the group docker, you either need to log out or reboot for the change to take effect and start the script again"
    exit
}


install_nvidia_docker()
{
    check_step_completion ${FUNCNAME[0]} && return
    print_step "installing nVidia docker"
    print_log "adding the package repositories for nVidia docker"
    # source: https://github.com/NVIDIA/nvidia-docker/blob/master/README.md
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    print_log "installing nVidia docker"
    sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit nvidia-container-runtime
    sudo systemctl restart docker
    flag_step_completion ${FUNCNAME[0]} && return
}


check_cuda_nvidia_docker()
{
    print_log "checking nvidia docker install"
    # testing the docker install
    print_log "# docker run --rm hello-world"
    docker run --rm hello-world | tee $checklog
    [[ $? -ne 0 ]] && exit
    # testing cuda support
    print_log "#docker run --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=all --rm nvidia/cuda nvcc -V"
    docker run -e NVIDIA_VISIBLE_DEVICES=all --rm nvidia/cuda nvcc -V | tree $checklog
    # source: http://collabnix.com/introducing-new-docker-cli-api-support-for-nvidia-gpus-under-docker-engine-19-03-0-beta-release/
    docker run --help | grep -i gpus | tee $checklog
    docker run --gpus all,capabilities=utility nvidia/cuda:${cudaver}-base nvidia-smi | tee $checklog
    # docker run -it --rm --gpus all ubuntu nvidia-smi -L

    # source: https://github.com/NVIDIA/nvidia-docker/wiki/Usage
    # For instance, if you are creating your own custom CUDA container, you should use the following:
    #ENV NVIDIA_VISIBLE_DEVICES all
    #ENV NVIDIA_DRIVER_CAPABILITIES compute,utility

    # print_log "downloading tensorflow models"
    # mkdir -p ~/work/tensorflow && cd ~/work/tensorflow
    # git clone https://github.com/tensorflow/models.git
    # cd models
    # # note: official/requirements.txt doesn't exist with r1.7.0
    # git branch -av
    # git checkout remotes/origin/r1.7.0
    
    # print_log "now to test tf gpu with cuda, you can run the MNIST workload with the following commands"
    # print_log "docker run -it --rm --name tf -p 8888:8888 -p 6006:6006 -v ~/work/tensorflow:/work tensorflow/tensorflow:1.7.0-devel-gpu-py3"
    # print_log 'export PYTHONPATH="$PYTHONPATH:/work/models"'
    # # cd /work/models
    # # not available for 1.7.0
    # # pip3 install --user -r official/requirements.txt
    
    # # MNIST workload
    # # source: https://github.com/tensorflow/models/blob/master/official/mnist/README.md
    # print_log "cd /work/models/official/mnist"
    # print_log "mkdir -p /work/mnist_saved_model"
    # # running and exporting the model
    # print_log "python3 mnist.py --export_dir /work/mnist_saved_model --benchmarks=."
}


log_script_start
check_requirements
cleanup_pkg
install_docker
install_nvidia_docker
check_cuda_nvidia_docker
log_script_end
