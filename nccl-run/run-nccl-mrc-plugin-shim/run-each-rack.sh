#!/bin/bash
#

#mapfile -t RACK_LIST < <(ls hostfile-F02C04C002-*)
RACK_LIST=(hostfile-F02C04C002-CC422 hostfile-F02C04C002-CC427)

for rack in "${RACK_LIST[@]}"; do
    echo "### Running on $rack ###"

    rack_name=$(echo $rack | cut -d- -f2-3)
    HOSTFILE=./$rack ./run-nccl-mrc-plugin.sh 16 sendrecv 2>&1 | tee mrc-plugin-sendrecv-${rack_name}-r2.log
    #HOSTFILE=./$rack ./run-nccl-mrc-plugin-mnnvl.sh 16 all_gather 2>&1 | tee mrc-plugin-allgather-${rack_name}-r2.log
done
