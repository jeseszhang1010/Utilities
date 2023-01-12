#!/bin/bash

if [ $# -ne 5 ]; then
    echo "Invalid usage: $0 <scale> <hostfile> <ppn> <pt2pt/coll/path-bench> <bench-args>"
    exit -1
fi

SCALE=$1
HOSTFILE=$2
PPN=$3
BENS=$4
ARGS=$5
LOGDIR=$PWD/$(basename $HOSTFILE)-scale/r2

for i in `./generate-group.py $SCALE $HOSTFILE` 
do
    echo $i
    ./run-mpi.pbs-specific.sh $SCALE $i $LOGDIR $PPN $BENS "$ARGS"
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

