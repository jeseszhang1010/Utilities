#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Invalid usage: $0 <hostfile> <ALLTOALL=0|1>"
    exit -1
fi

HOSTFILE=$1
ALLTOALL=$2
LOGDIR=$(basename $HOSTFILE)-pairs

for i in `./generate-pairs.py $HOSTFILE`
do
    ./run-nccl-allred.pbs-specific.sh 2 $i 0 $ALLTOALL $LOGDIR
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

