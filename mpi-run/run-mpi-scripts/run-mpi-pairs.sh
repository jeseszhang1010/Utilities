#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Invalid usage: $0 <hostfile>"
    exit -1
fi

HOSTFILE=$1
LOGDIR=$PWD/$(basename $HOSTFILE)-pairs

for i in `./generate-pairs.py $HOSTFILE`
do
    ./run-mpi.pbs-specific.sh 2 $i $LOGDIR 1 pt2pt "-m 8388608"
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

