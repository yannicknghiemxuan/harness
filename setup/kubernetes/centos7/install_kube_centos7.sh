#!/usr/bin/env bash
# source: https://docs.openstack.org/kolla-kubernetes/latest/deployment-guide.html
#set -euxo pipefail
set -x

regularuser=tnx
# 18.09 is the last supported version by kube as per this link:
# https://kubernetes.io/docs/setup/release/notes/
docker_ver=18.09.8

# default values to be over-riden by mykubeconf
podnet_cidr="172.1.0.0/16"
service_cidr="172.2.0.0/24"
advertise_addr="10.1.3.59"
myhostname=controlnode.localdomain
myhosttype=controlnode

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
	sed -i "s@$myoldhostname@$myhostname@g" /etc/hosts
    fi
}


install_base()
{
    yum upgrade -y
    yum install -y tree emacs-nox net-tools wget
    # EPEL packages
    wget dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
    rpm -ihv epel-release-7-11.noarch.rpm
    rm epel-release-7-11.noarch.rpm
    yum install -y htop
}


# sources:
# - https://docs.docker.com/install/linux/docker-ce/centos/
# - https://kubernetes.io/docs/setup/production-environment/container-runtimes/
install_docker()
{
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo \
       https://download.docker.com/linux/centos/docker-ce.repo
    # to list the available versions:
    # yum list docker-ce --showduplicates | sort -r
    yum install -y docker-ce-${docker_ver} docker-ce-cli-${docker_ver}
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
    systemctl enable docker
    systemctl start docker
}


# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# this needs to be installed on both controller and worker nodes
install_kube()
{
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
    yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    systemctl enable --now kubelet
    tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
    sysctl --system
    # make sure br_netfilter is active
    lsmod | grep br_netfilter >/dev/null 2>&1
    [[ $? -ne 0 ]] && modprobe br_netfilter
    echo "do not power down or restart the host. Instead, continue directly to the next section to create your cluster."
    echo "source: https://docs.projectcalico.org/v3.8/getting-started/kubernetes/"
}


# here is a link comparing the different pod network solutions:
# https://kubedex.com/kubernetes-network-plugins/
# Flannel is the oldest and arguably most mature plugin but it has the fewest features.
# It’s really common for people to combine Flannel and Calico together into what used to
# be called ‘Canal’. It seems the Canal project has died and both Flannel and Calico
# develop separately but maintain good documentation for combining together.
# his advice:
# start with Calico and only deviate if you need something that it does not provide.
install_pod_network()
{
    # Calico guide:
    # https://docs.projectcalico.org/v3.8/getting-started/kubernetes/

    # configure NetworkManager
    # https://docs.projectcalico.org/v3.8/maintenance/troubleshooting#configure-networkmanager
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
}


deploy_kube()
{
    # Deploy Kubernetes with kubeadm
    # added --apiserver-advertise-address because by default kubeadm uses the network
    # interface associated with the default gateway
    # source: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#instructions
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
    # By default, kubernetes cluster will not schedule pods on the master node for security reasons.
    # But if we would like to be able to schedule pods on the master node, e.g: for a single-node
    # kubernetes cluster for testing and development purposes, we can run “$ kubectl taint” command.
    # details: https://itnext.io/understanding-kubectl-taint-e6f299d3851f
    kubectl taint nodes --all=true node-role.kubernetes.io/master:NoSchedule-
}


wait_for_kube_readiness()
{
    # waits for kubernetes to complete the initialization
    while true; do
	echo "waiting for the coredns pods to start"
	which kubectl >/dev/null 2>&1
	if [[ $? -eq 0 ]]; then
	    kubectl get pods --all-namespaces | grep coredns | grep -E '[1-9]/' >/dev/null
	    [[ $? -ne 0 ]] && break
	fi
	sleep 1
    done
    echo "kubernetes has initialized"
}


validate_kube()
{
    kubectl get nodes -o wide
    echo "kubernetes installation validation"
    echo "type: \"nslookup kubernetes\" within the busybox container (there should be no error):"
    kubectl run -i --rm -t $(uuidgen) --image=busybox --restart=Never
    # link to debug dns issues:
    # https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/
}


configure_os
# install_base
# install_docker

# install_kube
# deploy_kube
# wait_for_kube_readiness

# validate_kube
