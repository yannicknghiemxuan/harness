#!/usr/bin/env bash
# to be installed on the master node only
# target OS: centos
# sources:
# - https://medium.com/@wilson.wilson/install-heketi-and-glusterfs-with-openshift-to-allow-dynamic-persistent-volume-management-89156340b2bd
# - https://access.redhat.com/documentation/en-us/red_hat_gluster_storage/3.1/html/administration_guide/ch06s02
set -x
[[ ! -f heketi_env ]] && echo "error: heketi_env is missing" && exit 1
[[ ! -f topology.json ]] && echo "error: topology.json is missing" && exit 1
. ./heketi_env

backup_file()
{
    [[ ! -f $1 ]] && return
    [[ ! -f ${1}_orig ]] && cp $1 ${1}_orig
}


install_packages()
{
    yum update
    yum install -y heketi heketi-client heketi-templates
    yum versionlock heketi heketi-client heketi-templates
}


configure_heketi()
{
    [[ ! -f /home/ansible/.ssh/id_rsa ]] && echo "error: no id_rsa file found for ansible user" && exit 1
    gluster volume list
    cp /home/ansible/.ssh/id_rsa /etc/heketi/heketi_key
    chown heketi /etc/heketi/heketi_key
    backup_file /etc/heketi/heketi.json
    mkdir generated
    openssl rand -base64 14 > generated/admin_pass
    openssl rand -base64 14 > generated/user_pass
    chmod 700 generated
    chmod 600 generated/*
    sed -e "s@__PASSWORD_ADMIN__@$(cat generated/admin_pass)@" \
	-e "s@__PASSWORD_USER__@$(cat generated/user_pass)@" \
	-e "s@__KUBE_HOST__@$mykubehost@" \
	-e "s@__KUBE_USER__@$mykubeuser@" \
	-e "s@__KUBE_PASSWORD__@$mykubepassword@" \
	-e "s@__KUBE_NAMESPACE__@$mykubenamespace@" \
	< heketi.json_template \
	> /etc/heketi/heketi.json
    systemctl start heketi
    heketi-cli --server http://$mykubehost:8080 \
               --user admin \
	       --secret "$(cat generated/admin_pass)" \
               topology load \
               --json=topology.json
    systemctl enable heketi
    systemctl restart heketi
    echo "is heketi responding?"
    curl http://$mykubehost:8080/hello
}


configure_kubernetes()
{
    # source: https://kubernetes.io/docs/concepts/storage/storage-classes/
    echo "in SC_Heketi.yml change to volumetype: replicate:3 for production"
    tee SC_Heketi.yml <<EOF
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: heketi
provisioner: kubernetes.io/glusterfs
parameters:
  resturl: "http://$mykubehost:8080"
  restuser: "admin"
  restuserkey: "$(cat generated/admin_pass)"
  volumetype: none
EOF
    # this creates the kubernetes storage class
    kubectl apply -f SC_Heketi.yml -n default
    # source: https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/
    kubectl patch storageclass heketi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    kubectl get sc -o wide
    kubectl get pv -o wide
}


test_config()
{
    tee pvctest_heketi.yml <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: pvctestheketi 
 annotations:
   volume.beta.kubernetes.io/storage-class: heketi  
spec:
 accessModes:
  - ReadWriteMany
 resources:
   requests:
     storage: 1G
EOF
    tee pvctest_default.yml <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: pvctestdefault 
spec:
 accessModes:
  - ReadWriteMany
 resources:
   requests:
     storage: 1G
EOF
    kubectl get sc -o wide
    kubectl apply -f pvctest_heketi.yml -n default
    kubectl apply -f pvctest_default.yml -n default
    sleep 5
    kubectl get pvc -o wide
    kubectl delete pvc pvctestdefault pvctestheketi
}


install_packages
configure_heketi
configure_kubernetes
test_config
echo "to check the logs: journalctl -u heketi"
echo "to debug:"
echo "  kubectl describe pvc <>"
echo "  kubectl get svc | grep glusterfs"
echo ""
echo "you also should configure the firewall"


 # 2150  heketi-cli --server http://$mykubehost:8080 --user admin --secret "$(cat generated/admin_pass)" volume create --size=1
 # 2151  heketi-cli --server http://$mykubehost:8080 --user admin --secret "$(cat generated/admin_pass)" volume list
 # 2152  heketi-cli --server http://$mykubehost:8080 --user admin --secret "$(cat generated/admin_pass)" node list
 # 2153  heketi-cli --server http://$mykubehost:8080 --user admin --secret "$(cat generated/admin_pass)" node info aa4721f3ef46e054e973396c1deda2ec
 # 2154  heketi-cli --server http://$mykubehost:8080 --user admin --secret "$(cat generated/admin_pass)" node info c0af6f79e5cf82d0714809c41e507419
# failed -> it did not create bricks, reason is minimum number of nodes to have durability is 3
# to override:
# heketi-cli --server http://$mykubehost:8080 --user admin --secret "$(cat generated/admin_pass)" volume create --durability=none --size=1

