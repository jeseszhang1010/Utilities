#!/bin/bash

# This script assumes the pbs output files (*.OU)
# are placed under ${LOG_PATH},
# 

if [ $# -ne "1" ]; then
    echo "Usage: $0 <LOGPATH>"
    exit 1
fi
LOG_PATH=$1


# Generate scale-2-comb-16g.dat:
# Go to nccl-allred-2 directory,
# extract BW data at 16g message size of all job output,
# save to scale-2-comb-16g.dat file

comb_16g_name=pairwise-16g

if [ -f "$comb_16g_name.dat" ]; then
    rm -rf $comb_16g_name.dat
fi

echo "Extracting BW at 16g msg size from scale-2-comb"
line=0
for f in $(find ${LOG_PATH} -type f -name '*.OU'); do
    line=$(($line+1))
    bw=$(cat $f | grep 17179869184 | tail -1 | awk '{print $12}')
    echo -e "$line\t${f}\t$bw" >> $comb_16g_name.dat
done

echo "Plotting with BW at 16g msg size of pairwise-16g"
#gnuplot pairwise-16g-point.plot && epstopdf pairwise-16g.eps && rm -rf pairwise-16g.eps

