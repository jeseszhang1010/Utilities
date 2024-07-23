#!/bin/bash
set -e

if [ $# -ne 7 ]; then
    echo "$0 <Subscription> <Location> <VmssName> <SshKeyPath> <PrivateKeyPath> <CloudInitPath> <ImageId>"
    exit 1
fi

Subscription=$1
Location=$2
VmssName=$3
SshKeyPath=$4
PrivateKeyPath=$5
CloudInitPath=$6
ImageId=$7
rg="jijos-${VmssName}-H100-OAI-rg"
AnfPoolSize=4
AnfVolumeSize=4096
	

Vnet="${VmssName}xVnet"
Subnet="${VmssName}xSubnet"
HeadNode="${VmssName}-headnode"
AnfName="${VmssName}anf"
AnfPool="${VmssName}pool"


az account set -s $Subscription

az group create -l $Location -n $rg --tag Owner=jijosdir

az network vnet create -g $rg -n $Vnet --address-prefix 10.0.0.0/16 --subnet-name $Subnet --subnet-prefixes 10.0.0.0/20

az network vnet subnet create -g $rg --vnet-name $Vnet -n anfSubnet --address-prefixes 10.0.16.0/20 --delegations "Microsoft.NetApp/volumes"

az vm create --resource-group $rg --name $HeadNode --size Standard_D32as_v4 --subnet $Subnet --vnet-name $Vnet  --image $ImageId --admin-username azhpcuser --ssh-key-values $SshKeyPath --public-ip-sku Standard --custom-data $CloudInitPath  --assign-identity /subscriptions/d71c7216-6409-45f8-be15-35cf57b8527c/resourcegroups/IBPulse-Resources/providers/Microsoft.ManagedIdentity/userAssignedIdentities/IBPulse-User /subscriptions/b6ea9bda-1730-4c5f-a35a-520e858a5780/resourcegroups/moneo-prom-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/moneo-identity

az vmss create -n $VmssName -g $rg --image $ImageId  --instance-count 0 --subscription $Subscription --custom-data $CloudInitPath --admin-username azhpcuser  --assign-identity /subscriptions/d71c7216-6409-45f8-be15-35cf57b8527c/resourcegroups/IBPulse-Resources/providers/Microsoft.ManagedIdentity/userAssignedIdentities/IBPulse-User /subscriptions/b6ea9bda-1730-4c5f-a35a-520e858a5780/resourcegroups/moneo-prom-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/moneo-identity  --subnet $Subnet  --vnet-name $Vnet  --lb-sku Standard --disable-overprovision  --accelerated-networking false --os-disk-size-gb 128  --platform-fault-domain-count 1 --single-placement-group false --ssh-key-values $SshKeyPath

az netappfiles account create -g $rg --name $AnfName -l $Location

az netappfiles pool create -g $rg --account-name $AnfName --name $AnfPool  -l $Location --size $AnfPoolSize --service-level premium

az netappfiles volume create -g $rg --account-name $AnfName --pool-name $AnfPool --name "anfvol" -l $Location --service-level premium --usage-threshold $AnfVolumeSize  --file-path "anfvol" --vnet $Vnet --subnet anfsubnet --protocol-types NFSv4.1 --allowed-clients 0.0.0.0/0 --rule-index 1 --has-root-access True

HeadNodeIp=$(az vm show -d -g $rg -n $HeadNode --query publicIps -o tsv)

MountTargetIp = az netappfiles volume show -g $rg -a $AnfName -p $AnfPool -v "anfvol" --query "mountTargets[].ipAddress" -o tsv

ssh -i $PrivateKeyPath azhpcuser@$HeadNodeIp -t "sudo mkdir /mnt/anfvol && sudo mount -t nfs -o rw,hard,rsize=262144,wsize=262144,sec=sys,vers=4.1,tcp ${MountTargetIp}:/anfvol /mnt/anfvol && sudo chmod 777 /mnt/anfvol"
