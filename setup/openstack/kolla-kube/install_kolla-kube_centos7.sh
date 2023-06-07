#!/usr/bin/env bash
# source: https://docs.openstack.org/kolla-kubernetes/latest/deployment-guide.html
#set -euxo pipefail
set -x

regularuser=tnx
# 18.09 is the last supported version by kube as per this link:
# https://kubernetes.io/docs/setup/release/notes/
docker_ver=18.09.8
# slides explaining how the networking works in kube:
# https://www.slideshare.net/CJCullen/kubernetes-networking-55835829
# podnet_cidr="11.1.0.0/16"
# service_cidr="11.3.3.0/24"
podnet_cidr="172.1.0.0/16"
service_cidr="172.2.0.0/24"
advertise_addr="10.1.3.59"

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


install_docker()
{
    # sources:
    # - https://docs.docker.com/install/linux/docker-ce/centos/
    # - https://kubernetes.io/docs/setup/production-environment/container-runtimes/
    yum install -y yum-utils \
       device-mapper-persistent-data \
       lvm2
    yum-config-manager \
       --add-repo \
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


install_kube()
{
    # Write the Kubernetes repository file
    [[ ! -f /etc/yum.repos.d/kubernetes.repo ]] && \
	tee /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    # Install Kubernetes 1.6.4 or later and other dependencies
    yum install -y ebtables kubeadm kubectl kubelet kubernetes-cni git gcc
    # Setup the DNS server with the service CIDR
    # backup_file /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    # sed -i 's/10.96.0.10/10.3.3.10/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    # Reload the hand-modified service files
    systemctl daemon-reload
    # Stop kubelet if it is running
    systemctl stop kubelet
    # Enable and start docker and kubelet
    systemctl enable kubelet
    systemctl start kubelet
    # pre-downloads the kube images
    kubeadm config images pull
    # kube wants this in the preflight checks
    if [[ ! -f /etc/sysctl.conf_orig ]]; then
	backup_file /etc/sysctl.conf
	echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
	sysctl -p
    fi
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
    # Deploy the Canal CNI driver
    # I think this one is not needed because the new version of canal contains both
    # curl -L https://raw.githubusercontent.com/projectcalico/canal/master/k8s-install/1.6/rbac.yaml -o rbac.yaml
    # kubectl apply -f rbac.yaml
    # curl -L https://raw.githubusercontent.com/projectcalico/canal/master/k8s-install/1.6/canal.yaml -o canal.yaml
    # using newer version from here:
    # https://docs.projectcalico.org/v3.8/getting-started/kubernetes/installation/flannel
    curl -L https://docs.projectcalico.org/v3.8/manifests/canal.yaml -o canal.yaml
    sed -i "s@10.244.0.0/16@${podnet_cidr}@g" canal.yaml
    kubectl apply -f canal.yaml
    # By default, kubernetes cluster will not schedule pods on the master node for security reasons.
    # But if we would like to be able to schedule pods on the master node, e.g: for a single-node
    # kubernetes cluster for testing and development purposes, we can run “$ kubectl taint” command.
    # details: https://itnext.io/understanding-kubectl-taint-e6f299d3851f
    kubectl taint nodes --all=true node-role.kubernetes.io/master:NoSchedule-
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
    echo "kubernetes installation validation"
    echo "type: \"nslookup kubernetes\" within the busybox container (there should be no error):"
    kubectl run -i --rm -t $(uuidgen) --image=busybox --restart=Never
    # link to debug dns issues:
    # https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/
}


deploy_kolla_kube()
{
    echo test
}


#configure_os
#install_base
#install_docker
#install_kube
deploy_kube
#validate_kube
# deploy_kolla_kube
