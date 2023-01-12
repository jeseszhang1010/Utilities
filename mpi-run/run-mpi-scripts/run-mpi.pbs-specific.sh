#!/bin/bash

if [ $# -ne 6 ]; then
    echo $#
    echo "Invalid usage: $0 <#nodes> <nodelist> <log-dir> <ppn> <pt2pt/coll/bench-path> <bench-args>"
    exit -1
fi

NODES=$1
NODES_LIST=$2
LOGDIR=$3
PPN=$4
BENS=$5
ARGS=$6
SHARP=0

declare -a pt2ptbench=(latency bw bibw)
declare -a collbench=(barrier bcast allgather allreduce alltoall)
#declare -a collbench=(allreduce)


if [ "$BENS" = "pt2pt" ]; then
    benchmarks=${pt2ptbench[@]}
elif [ "$BENS" = "coll" ]; then
    benchmarks=${collbench[@]}
elif [ -n "$BENS" ]; then
    benchmarks=$BENS
else
    echo "Error: No benchmark specified, can be pt2pt, coll, or path to benchmark, exiting"
    exit -1
fi

#NODENAMES=$(sed 's/:ppn=176+*/,/g' <<<"$NODES_LIST")
SCRIPTPATH=$PWD

for bench in ${benchmarks[@]}; do

    #echo $bench
    JOBNAME="${NODES}-$(basename ${bench})"
    LOG_SUBDIR="${LOGDIR}/${JOBNAME}"
    mkdir -p ${LOG_SUBDIR}
    
    # Run benchmarks across specified nodes
    qsub -N ${JOBNAME} -l nodes=${NODES_LIST} -o ${LOG_SUBDIR} -e ${LOG_SUBDIR} \
	    -v BENCH=${bench},ARGS="${ARGS}",NODES=${NODES},PPN=${PPN},SHARP=${SHARP},NODES_LIST=${NODES_LIST} ${SCRIPTPATH}/run-mpi.pbs
done
