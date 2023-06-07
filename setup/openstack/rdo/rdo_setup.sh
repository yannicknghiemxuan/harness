#!/usr/bin/env bash

source /root/keystonerc_admin

# great tutorial:
# https://developer.openstack.org/firstapp-libcloud/getting_started.html
# -> great networking section

### network
# floating ip range for the virtual machines to be reachable from lan
# source: https://www.rdoproject.org/networking/floating-ip-range/
# -> this link shows usage of deprecated command, use openstack CLI instead
# network creation guide: https://docs.openstack.org/ocata/user-guide/cli-create-and-manage-networks.html
# creation of the network
ip a # check
openstack network create --provider-network-type flat lan_network
openstack network list # check
# creation of a subnet and associate it to the network
nmap -sn 192.168.0.224/27 # check of the IPs in the range
openstack subnet create --subnet-range 192.168.0.224/27 --network lan_network --gateway 192.168.0.1 lan_subnetpool
# can also use  --allocation-pool start=<ip-address>,end=<ip-address> instead of --subnet-range
# more options here: https://docs.openstack.org/python-openstackclient/pike/cli/command-objects/subnet.html
openstack subnet list # check
# creation of a router
openstack router create lan_router
openstack router list # check
# creation of a public ip
#openstack floating ip create lan_network
# and then creates a mapping to the external network
openstack router set lan_router --external-gateway lan_network
