#!/bin/bash

if [ $# -ne 5 ]; then
    echo "Invalid usage: $0 <scale> <hostfile> <ALLTOALL=0|1> <alg=tree/ring> <proto=ll/ll128/simple>"
    exit -1
fi

SCALE=$1
HOSTFILE=$2
ALLTOALL=$3
ALG=$4
PROTO=$5
PHASE_DIR=$(basename $HOSTFILE)

for i in `./generate-group.py $SCALE $HOSTFILE`
do
    echo $i
    ./run-nccl-allred.pbs-specific.sh $SCALE $i 0 $ALLTOALL ${ALG} ${PROTO} $PHASE_DIR
    do_wait=1
    while [ $do_wait -eq 1 ]
    do
        QUEUE_LEN=`qstat | wc -l`
        if [ $QUEUE_LEN -gt 1000 ] ; then
            echo -n "."
            sleep 10
        else
            do_wait=0
        fi
    done
done

