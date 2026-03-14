#!/bin/bash
#

HF=hostfile-one-per-rack.txt

myip=$(ip -br addr show | grep enP22 | awk '{print $3}' | cut -d/ -f1)
echo "My IP is $myip"

mapfile -t RACK_LIST < <(ls hostfile-F02C04C002-*)

for rack in "${RACK_LIST[@]}"; do
    rack_name=$(echo $rack | cut -d- -f2-3)
    if grep -qFx ${myip} ${rack}; then
        echo "### Running on $rack ###"
        #HOSTFILE=./$rack ./run-nccl-mrc-plugin.sh 16 sendrecv 2>&1 | tee mrc-plugin-sendrecv-${rack_name}-par.log
        HOSTFILE=./$rack ./run-nccl-mrc-plugin-mnnvl.sh 16 all_gather 2>&1 | tee mrc-plugin-allgather-${rack_name}-par.log
	scp mrc-plugin-*-${rack_name}-par.log 180.100.0.10:~/zhanj/precheck/
    fi
done
