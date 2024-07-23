#!/bin/bash

sub=9cd0dc62-fcc2-4b6b-abd3-6010a01a8109
suffix=h200
region=eastus2euap
resource_gp_name=zhanj-rg-$region-$suffix
nsg_name=zhanj-nsg-$region-$suffix
vnet_name=zhanj-vnet-$region-$suffix
subnet_name=zhanj-subnet-$region-$suffix
vmss_name=zhanj-vmss-$region-$suffix
cnt=0
img_loc="/subscriptions/d2c9544f-4329-4642-b73d-020e7fef844f/resourceGroups/azhpc-images-rg/providers/Microsoft.Compute/galleries/AzHPCImageRelease/images/UbuntuHPC-22.04-gen2/versions/2024.0619.0"
#img_loc=almalinux:almalinux-hpc:8_7-hpc-gen2:8.7.2023111401
sku_name=Standard_ND96isr_H200_v5
username=hpcuser



az account set --subscription $sub

## create resource group
#az group create --name $resource_gp_name --location $region --tags "Owner=zhanj"
#
## create network security group
#az network nsg create --name $nsg_name --resource-group $resource_gp_name --location $region
#
## create virtual network with a specific address prefix and one subnet
#az network vnet create --name $vnet_name --resource-group $resource_gp_name --address-prefix 10.0.0.0/16 --subnet-name $subnet_name --subnet-prefix 10.0.0.0/24

# create a VM scale set
# To scale up to more than 100 VMs, set single-placement-group to false; this is typically during cluster buildout, and pkey disabled
# To scale up VMs on a production cluster, where pkey has been enabled, set single-placement-group to true
az vmss create --name  $vmss_name --resource-group $resource_gp_name \
               --admin-username $username --platform-fault-domain-count 1 --single-placement-group true \
               --instance-count $cnt \
               --image microsoft-dsvm:ubuntu-hpc:2204:22.04.2024062401 \
               --vm-sku $sku_name \
               --vnet-name $vnet_name --subnet $subnet_name --nsg $nsg_name \
               --lb-sku Standard \
               --ssh-key-values /home/zhanj/.ssh/id_rsa.pub
