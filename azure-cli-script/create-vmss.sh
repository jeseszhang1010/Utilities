#/bin/bash

suffix=470
region=westeurope
resource_gp_name=zhanj-rg-$region-$suffix
nsg_name=zhanj-nsg-$region-$suffix
vnet_name=zhanj-vnet-$region-$suffix
subnet_name=zhanj-subnet-$region-$suffix
vmss_name=zhanj-vmss-$region-$suffix
cnt=2
#img_loc="/subscriptions/d2c9544f-4329-4642-b73d-020e7fef844f/resourceGroups/azhpc-images-rg/providers/Microsoft.Compute/galleries/AzHPCImageGallery/images/UbuntuHPC-18.04-gen2/versions/4.0.0"
img_loc="microsoft-dsvm:ubuntu-hpc:1804:18.04.2021120101"
sku_name=Standard_ND96amsr_A100_v4

# create resource group
az group create --name $resource_gp_name --location $region

# create network security group
az network nsg create --name $nsg_name --resource-group $resource_gp_name --location $region
	
# create virtual network with a specific address prefix and one subnet
az network vnet create --name $vnet_name --resource-group $resource_gp_name --address-prefix 10.0.0.0/16 --subnet-name $subnet_name --subnet-prefix 10.0.0.0/24
	
# create a VM scale set
az vmss create --name  $vmss_name --resource-group $resource_gp_name \
	       --admin-username azureuser --single-placement-group true  \
	       --instance-count $cnt \
	       --image $img_loc \
	       --vm-sku $sku_name \
	       --vnet-name $vnet_name --subnet $subnet_name --nsg $nsg_name \
	       --public-ip-per-vm --ssh-key-values ../laptop-keys/id_rsa.pub  --lb ""

