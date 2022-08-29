#!/bin/bash

# This script assumes the pbs output files (*.o*)
# are placed under ${LOG_PATH}-{scale},
# 


LOG_PATH=/dev/shm/phase2-pair-wise/nccl-allred-phase2-2n-0822


msgunit=(4 8 16 32 64 128 256 512 1K 2K 4K 8K 16K 32K 64K 128K 256K 512K 1M 2M 4M 8M 16M 32M 64M 128M 256M 512M 1G 2G 4G 8G 16G)

add_msg_unit() {
    local fn=$1
    for l in $(seq 1 32); do
        sed -i "$l s/^/${msgunit[$l]}\t/" $fn
    done
}

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
for f in $(find ${LOG_PATH} -type f -name '*.o*'); do
    line=$(($line+1))
    bw=$(cat $f | grep 17179869184 | tail -1 | awk '{print $11}')
    echo -e "$line\t${f}\t$bw" >> $comb_16g_name.dat
done

echo "Plotting with BW at 16g msg size of pairwise-16g"
gnuplot pairwise-16g-point.plot && epstopdf pairwise-16g.eps && rm -rf pairwise-16g.eps

