#!/bin/bash

# This script assumes the pbs output files (*.o*)
# are placed under ${LOG_PATH}-{scale},
# e.g.,
# all node pairs with distance 2 output (*.o*) are placed under ${LOG_PATH}-2.
# Thus, set the variable LOG_PATH based on your layout.
# 

LOG_PATH=/dev/shm/final/allreduce/topo-aware/nccl-allred-2-dist


for g in 2 4 6; do
    dist_16g=nccl-allred-2-dist-$g

    if [ -f "${dist_16g}.dat" ]; then
        rm -rf $dist_16g.dat
    fi
    
    echo "Extracting BW at 16g msg size from $LOG_PATH-${g}"
    line=0
    for f in $(find ${LOG_PATH}-${g} -type f -name '*.o*'); do
        line=$(($line+1))
        bw=$(cat $f | grep 17179869184 | tail -1 | awk '{print $11}')
        echo -e "$line\t${f}\t$bw" >> $dist_16g.dat
    done
    echo "Plotting with BW at 16g msg size from $LOG_PATH-${g}"
done
gnuplot scale-2-topo-aware-point.plot && epstopdf scale-2-topo-aware-16g.eps && rm -rf scale-2-topo-aware-16g.eps

