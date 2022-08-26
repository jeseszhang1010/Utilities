#!/bin/bash

if [ $# -ne 7 ]; then
    echo "Invalid usage: $0 <no. of nodes> <nodelist> <LOCAL=0|1> <ALLTOALL=0|1> <alg> <proto> <phase dir>"
    exit -1
fi

NODES=$1
NODES_LIST=$2
SHARP=0
LOCAL=$3
ALLTOALL=$4
ALG=$5
PROTO=$6
PHASE_DIR=$7


NODENAMES=$(sed 's/:ppn=96+*/_/g' <<<"$NODES_LIST")

LOGDIR_PREFIX="nccl-allred-${ALG}-${PROTO}"
if [ $ALLTOALL -eq "1" ]; then
    LOGDIR_PREFIX="nccl-alltoall-${ALG}-${PROTO}"
fi


LOGDIR="${PHASE_DIR}-scale-res-$(date +%F)/${LOGDIR_PREFIX}-${NODES}"
JOBNAME="${NODES}-nccl-${ALG}-${PROTO}"

if [ $LOCAL -eq "1" ]; then
	LOGDIR="${LOGDIR_PREFIX}-local"
fi

mkdir -p ./${LOGDIR}
cd ${LOGDIR}

# Run NCCL allreduce
qsub -N ${JOBNAME} -l nodes=${NODES_LIST} \
     -v NODES=${NODES},SHARP=${SHARP},NODES_LIST=${NODES_LIST},LOCAL=${LOCAL},ALLTOALL=${ALLTOALL},ALG=${ALG},PROTO=${PROTO} \
     /home/jijos/zhanj/nccl-pbs/run-nccl-allred.pbs
