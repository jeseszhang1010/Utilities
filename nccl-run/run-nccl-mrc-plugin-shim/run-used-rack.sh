#!/bin/bash
#

mapfile -t RACK_LIST < <(ls hostfile-F02C04C002-*)

for rack in "${RACK_LIST[@]}"; do
    #echo "### Running on $rack ###"

    usedrow=$(grep -Fx -f row1-ips.txt $rack | wc -l)
    if [[ "$usedrow" -ne 0 ]]; then
        echo "Running on $rack used by other experiments previosuly"

        rack_name=$(echo $rack | cut -d- -f2-3)
    	HOSTFILE=./$rack ./run-nccl-mrc-plugin.sh 16 sendrecv 2>&1 | tee mrc-plugin-sendrecv-${rack_name}.log
    	HOSTFILE=./$rack ./run-nccl-mrc-plugin-mnnvl.sh 16 all_gather 2>&1 | tee mrc-plugin-allgather-${rack_name}.log
    fi 
done
