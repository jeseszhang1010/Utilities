#!/bin/bash

if [ $# -ne 5 ]; then
    echo "Invalid usage: $0 <no. of nodes> <nodelist> <LOCAL=0|1> <ALLTOALL=0|1> <log-dir>"
    exit -1
fi

NODES=$1
NODES_LIST=$2
SHARP=0
LOCAL=$3
ALLTOALL=$4
LOGDIR=$5


NODENAMES=$(sed 's/:ppn=96+*/_/g' <<<"$NODES_LIST")

LOGDIR_PREFIX="nccl-allreduce"
if [ $ALLTOALL -eq "1" ]; then
    LOGDIR_PREFIX="nccl-alltoall"
fi


LOGDIR="${LOGDIR}-${LOGDIR_PREFIX}-${NODES}"
JOBNAME="${NODES}-nccl"

if [ $LOCAL -eq "1" ]; then
	LOGDIR="${LOGDIR_PREFIX}-local"
fi

mkdir -p ./${LOGDIR}
cd ${LOGDIR}

# Run NCCL allreduce
qsub -N ${JOBNAME} -l nodes=${NODES_LIST} -v NODES=${NODES},SHARP=${SHARP},NODES_LIST=${NODES_LIST},LOCAL=${LOCAL},ALLTOALL=${ALLTOALL} ../run-nccl-allred.pbs
