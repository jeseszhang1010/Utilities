#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Invalid usage: $0 <scale> <hostfile> <ALLTOALL=0|1>"
    exit -1
fi

SCALE=$1
HOSTFILE=$2
ALLTOALL=$3
LOGDIR=$(basename $HOSTFILE)-scale

for i in `./generate-group.py $SCALE $HOSTFILE`
do
    echo $i
    ./run-nccl-allred.pbs-specific.sh $SCALE $i 0 $ALLTOALL $LOGDIR
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

