#!/bin/bash

sub=hpcscrub1
suffix=hbv4
region=eastus
resource_gp_name=zhanj-rg-$region-$suffix
nsg_name=zhanj-nsg-$region-$suffix
vnet_name=zhanj-vnet-$region-$suffix
subnet_name=zhanj-subnet-$region-$suffix
vmss_name=zhanj-vmss-$region-$suffix
cnt=0
img_loc=almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023060101
sku_name=Standard_NC24s_v3 #Standard_D16s_v3
username=hpcuser
headname=headnode
ssh_key="/home/zhanj/.ssh/id_rsa.pub"

az account set --subscription $sub

az vm create \
    --subscription $sub \
    --name $headname \
    --resource-group $resource_gp_name \
    --admin-username $username \
    --size $sku_name \
    --image $img_loc \
    --vnet-name $vnet_name \
    --subnet $subnet_name \
    --os-disk-size-gb 256 \
    --ssh-key-values $ssh_key
