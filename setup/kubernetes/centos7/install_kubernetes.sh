#!/usr/bin/env bash
# supported platforms:
# - CentOS 7
# - Ubuntu 18.04
#
# make sure that:
# - /etc/hosts is updated on all the cluster
set -x

. /etc/os-release

regularuser=tnx
# 18.09 is the last supported version by kube as per this link:
# https://kubernetes.io/docs/setup/release/notes/
docker_ver=18.09.8
kube_ver=1.15.4-0

# default values to be over-riden by mykubeconf
#podnet_cidr="172.1.0.0/16"
#service_cidr="172.2.0.0/24"
podnet_cidr="10.244.0.0/16"
service_cidr="10.245.0.0/24"
advertise_addr="192.168.0.73"
myhostname=controlnode.localdomain
myhosttype=controlnode
# can be calico, flannel
# note: I had issues with calico in the past where I had to manually flush iptables
#   I did not investigate these issues but flannel seems to work out of the box
podnetwork=flannel

# slides explaining how the networking works in kube:
# https://www.slideshare.net/CJCullen/kubernetes-networking-55835829
[[ ! -f mykubeconf ]] && exit
. mykubeconf

# to monitor the installation of kube, use:
# watch -d kubectl get pods --all-namespaces

backup_file()
{
    [[ ! -f $1 ]] && return
    [[ ! -f ${1}_orig ]] && cp $1 ${1}_orig
}


configure_os()
{
    # removes the swap, kubernetes does not support it
    swapoff -a
    backup_file /etc/fstab
    grep -v -E swap /etc/fstab > /tmp/fstab && mv /tmp/fstab /etc/fstab
    # Turn off SELinux:
    setenforce 0
    backup_file /etc/selinux/config
    sed -i 's/enforcing/disabled/g' /etc/selinux/config
    # Turn off firewalld
    systemctl stop firewalld
    systemctl disable firewalld
    # updates the /etc/hosts file
    backup_file /etc/hosts
    [[ ! myhosts ]] && exit
    cp /etc/hosts_orig /etc/hosts
    cat myhosts >> /etc/hosts
    # sets the hostname
    myoldhostname=$(uname -n)
    if [[ $myoldhostname != $myhostname ]]; then
	hostnamectl set-hostname $myhostname
	backup_file /etc/hosts
	sed -i "s@$myoldhostname@$myoldhostname $myhostname@g" /etc/hosts
    fi
}


install_base()
{
    case $ID in
	centos)
	    yum upgrade -y
	    yum install -y tree emacs-nox net-tools wget
	    # EPEL packages
	    wget dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
	    rpm -ihv epel-release-7-11.noarch.rpm
	    rm epel-release-7-11.noarch.rpm
	    yum install -y htop
	    ;;
	ubuntu)
	    apt-get update && apt-get dist-upgrade -y
	    apt-get install -y emacs-nox net-tools wget htop
	    ;;
	*)
	    exit 1
	    ;;
    esac
}


# sources:
# - https://docs.docker.com/install/linux/docker-ce/centos/
# - https://kubernetes.io/docs/setup/production-environment/container-runtimes/
install_docker()
{
    case $ID in
	centos)
	    yum install -y yum-utils device-mapper-persistent-data lvm2
	    yum-config-manager --add-repo \
			       https://download.docker.com/linux/centos/docker-ce.repo
	    # to list the available versions:
	    # yum list docker-ce --showduplicates | sort -r
	    yum install -y docker-ce-$docker_ver docker-ce-cli-$docker_ver
	    yum versionlock docker-ce-$docker_ver docker-ce-cli-$docker_ver
	    # changing cgroup driver from cgroupfs to systemd as per kube requirement
	    # create /etc/docker directory.
	    mkdir -p /etc/docker
	    # setup daemon.
	    backup_file /etc/docker/daemon.json
	    tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
	    mkdir -p /etc/systemd/system/docker.service.d
	    # enable and start Docker
	    systemctl daemon-reload
	    systemctl enable --now docker
	    ;;
	ubuntu)
	    apt-get update
	    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
	    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
	    add-apt-repository \
		"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	    ## Install Docker CE.
	    apt-get update
	    apt-get install -y docker-ce=${docker_ver}~ce~3-0~ubuntu-bionic
	    apt-mark hold docker-ce
	    # Setup daemon.
	    cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
	    mkdir -p /etc/systemd/system/docker.service.d
	    # Restart docker.
	    systemctl daemon-reload
	    systemctl restart docker
	    ;;
    esac
    usermod -aG docker $regularuser
}


# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# this needs to be installed on both controller and worker nodes
install_kube()
{
    if [[ $myhosttype == workernode ]]; then
        echo "type this command on the master node to get the join command:"
        echo "kubeadm token create --print-join-command"
        return
    fi
    case $ID in
	centos)
	    # Write the Kubernetes repository file
	    [[ ! -f /etc/yum.repos.d/kubernetes.repo ]] && \
		tee /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
	    # set firewall options on CentOS
	    yum install -y kubelet-$kube_ver kubeadm-$kube_ver kubectl-$kube_ver --disableexcludes=kubernetes
	    yum versionlock kubelet-$kube_ver kubeadm-$kube_ver kubectl-$kube_ver
	    systemctl enable --now kubelet
	    tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
	    sysctl --system
	    # make sure br_netfilter is active
	    lsmod | grep br_netfilter >/dev/null 2>&1
	    [[ $? -ne 0 ]] && modprobe br_netfilter
	    ;;
	ubuntu)
	    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
	    apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
	    apt-get update
	    apt-get install -y kubeadm=${kube_ver}0 kubectl=${kube_ver}0 kubelet=${kube_ver}0 kubernetes-cni
	    apt-mark hold kubeadm kubectl kubelet kubernetes-cni
	    ;;
    esac
    echo "do not power down or restart the host. Instead, continue directly to the next section to create your cluster."
    echo "source: https://docs.projectcalico.org/v3.8/getting-started/kubernetes/"
}


# here are links comparing the different pod network solutions:
# - https://kubernetes.io/docs/concepts/cluster-administration/networking/
# - https://kubedex.com/kubernetes-network-plugins/
# - https://docs.google.com/spreadsheets/d/1qCOlor16Wp5mHd6MQxB5gUEQILnijyDLIExEpqmee2k/edit?pli=1#gid=0
# Flannel is the oldest and arguably most mature plugin but it has the fewest features.
# It’s really common for people to combine Flannel and Calico together into what used to
# be called ‘Canal’. It seems the Canal project has died and both Flannel and Calico
# develop separately but maintain good documentation for combining together.
# his advice:
# start with Calico and only deviate if you need something that it does not provide.
install_pod_network()
{
    case $podnetwork in
	calico)
	    # Calico guide:
	    # https://docs.projectcalico.org/v3.9/getting-started/kubernetes/
	    # configure NetworkManager
	    # https://docs.projectcalico.org/v3.9/maintenance/troubleshooting#configure-networkmanager
	    if [[ ! -f /etc/NetworkManager/conf.d/calico.conf ]]; then
		tee /etc/NetworkManager/conf.d/calico.conf <<EOF
[keyfile]	
unmanaged-devices=interface-name:cali*;interface-name:tunl*
EOF
	    fi
	    # https://docs.projectcalico.org/v3.8/getting-started/kubernetes/installation/flannel
	    curl -L https://docs.projectcalico.org/v3.8/manifests/calico.yaml -o calico.yaml
	    sed -i "s@192.168.0.0/16@${podnet_cidr}@g" calico.yaml
	    kubectl apply -f calico.yaml
	    [[ $? -ne 0 ]] && exit
	    ;;
	flannel)
	    # Flannel guide:
	    # https://github.com/coreos/flannel#flannel
	    curl -L https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
	    sed -i "s@10.244.0.0/16@${podnet_cidr}@g" kube-flannel.yml
	    kubectl apply -f kube-flannel.yml
	    ;;
	*)
	    exit 1
	    ;;
    esac
}


# baremetal installs of Kubernetes do not have a load balancer so we need to install one
# sources:
# - https://github.com/kubernetes/kubernetes/issues/36220
# - https://metallb.universe.tf
# configuration:
# - https://metallb.universe.tf/configuration/
install_baremetal_loadbalancer()
{
    kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml
    tee config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $advertise_addr
EOF
    kubectl apply -f config.yaml
}


deploy_kube()
{
    if [[ $myhosttype != controlnode ]]; then
	echo "to get the join string, type this command on the control node:"
	echo "kubeadm token create --print-join-command"
	return
    fi
    # Deploy Kubernetes with kubeadm
    # added --apiserver-advertise-address because by default kubeadm uses the network
    # interface associated with the default gateway
    # add --v 5 to debug
    # source: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#instructions
    # also check the --kubernetes-version option which permits to select the version of the control plane
    kubeadm init --pod-network-cidr=$podnet_cidr \
	 --service-cidr=$service_cidr \
	 --apiserver-advertise-address=$advertise_addr
    [[ $? -ne 0 ]] && exit
    # giving regularuser access to the kube cluster
    mkdir -p /home/$regularuser/.kube ~/.kube
    cp -i /etc/kubernetes/admin.conf /home/$regularuser/.kube/config
    cp -i /etc/kubernetes/admin.conf ~/.kube/config
    chown -R $regularuser:$regularuser /home/$regularuser/.kube
    install_pod_network
    install_baremetal_loadbalancer
    # By default, kubernetes cluster will not schedule pods on the master node for security reasons.
    # But if we would like to be able to schedule pods on the master node, e.g: for a single-node
    # kubernetes cluster for testing and development purposes, we can run “$ kubectl taint” command.
    # details: https://itnext.io/understanding-kubectl-taint-e6f299d3851f
    kubectl taint nodes --all=true node-role.kubernetes.io/master:NoSchedule-
}


configure_os
# install_base
# install_docker
# install_kube
# deploy_kube

echo "now you can install 1) heketi 2) helm"
