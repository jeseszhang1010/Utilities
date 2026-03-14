#!/bin/bash
#

TTHF=/home/azhpcuser/zhanj/hostfile-0313.txt

if false; then

if [[ -f "$TTHF" ]]; then
    rm "$TTHF"
fi

mapfile -t RACK_LIST < <(ls hostfile-F02C04C002-*)
BAD_RACKS=(hostfile-F02C04C002-CG423 hostfile-F02C04C002-DA421)

for rack in "${RACK_LIST[@]}"; do
    skip=false
    for bad in "${BAD_RACKS[@]}"; do
        if [[ "$rack" == "$bad" ]]; then
            skip=true
            break
        fi
    done
    if $skip; then
        echo "Skipping bad rack $rack"
        continue
    fi

    echo "### Extract IPs from $rack ###"
    #usedrow=$(grep -Fx -f row1-ips.txt $rack | wc -l)
    #if [[ "$usedrow" -ne 0 ]]; then
    #    echo "Skipping $rack used by other experiments: $usedrow IPs found in row1-ips.txt"
    #    continue
    #fi 
    cat $rack >> $TTHF
done

fi

TTHFCNT=$(cat $TTHF | wc -l)

kind=plugin
scale=2
while [[ $scale -le $TTHFCNT ]]; do
#while [[ $scale -le 2 ]]; do
    echo "### Running with scale $scale ###"
    
    HOSTFILE=$TTHF ./run-nccl-mrc-$kind.sh $scale sendrecv 2>&1 | tee mrc-$kind-sendrecv-scale-${scale}.log
    sleep 2
    #HOSTFILE=$TTHF ./run-nccl-mrc-$kind-mnnvl.sh $scale all_gather 2>&1 | tee mrc-$kind-allgather-scale-${scale}.log
    #sleep 2
    #HOSTFILE=$TTHF ./run-nccl-mrc-$kind-mnnvl.sh $scale all_reduce 2>&1 | tee mrc-$kind-allreduce-scale-${scale}.log
    #sleep 2
    #HOSTFILE=$TTHF ./run-nccl-mrc-$kind-mnnvl.sh $scale reduce_scatter 2>&1 | tee mrc-$kind-reducescatter-scale-${scale}.log
    #sleep 2
    #HOSTFILE=$TTHF ./run-nccl-mrc-$kind-mnnvl.sh $scale broadcast 2>&1 | tee mrc-$kind-broadcast-scale-${scale}.log
    #sleep 2
   
    if [[ $scale -eq $TTHFCNT ]]; then
	break
    fi

    # scale up
    scale=$((scale * 2))
    if [[ $scale -gt $TTHFCNT ]]; then
        scale=$TTHFCNT
    fi
done
