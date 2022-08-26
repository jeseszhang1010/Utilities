#!/bin/bash

# This script assumes the pbs output files (*.o*)
# are placed under ${LOG_PATH}-{scale},
# e.g.,
# all 2 nodes output (*.o*) are placed under ${LOG_PATH}-2.
# all 4 nodes output (*.o*) are placed under ${LOG_PATH}-4.
# Thus, set the variable LOG_PATH based on your layout.
# 


if [ $# -ne 2 ]; then
   echo "Usage: $0 <algo> <proto>"
   exit 1
fi

algo=$1
proto=$2

LOG_PATH=/home/zhanj/nccl/phase2-handover/phase2-vms-scale-res-2022-08-25/nccl-alltoall-$algo-$proto

#msgunit=(4 8 16 32 64 128 256 512 1K 2K 4K 8K 16K 32K 64K 128K 256K 512K 1M 2M 4M 8M 16M 32M 64M 128M 256M 512M 1G 2G 4G 8G 16G)
msgunit=(64 128 256 512 1K 2K 4K 8K 16K 32K 64K 128K 256K 512K 1M 2M 4M 8M 16M 32M 64M 128M 256M 512M 1G 2G 4G 8G 16G)

add_msg_unit() {
    local fn=$1
    for l in $(seq 1 32); do
        sed -i "$l s/^/${msgunit[$l]}\t/" $fn
    done
}

## Generate scale-2-comb-16g.dat:
## Go to nccl-allred-2 directory,
## extract BW data at 16g message size of all job output,
## save to scale-2-comb-16g.dat file
#
#comb_16g_name=scale-2-comb-16g
#
#if [ -f "$comb_16g_name.dat" ]; then
#    rm -rf $comb_16g_name.dat
#fi
#
#echo "Extracting BW at 16g msg size from scale-2-comb"
#line=0
#for f in $(find ${LOG_PATH} -type f -name '*.o*'); do
#    line=$(($line+1))
#    bw=$(cat $f | grep 17179869184 | tail -1 | awk '{print $10}')
#    #bw=$(cat $f | grep 8589934592 | tail -1 | awk '{print $10}')
#    echo -e "$line\t${f}\t$bw" >> $comb_16g_name.dat
#done
#echo "Plotting with BW at 16g msg size of scale-2-16g-comb"
#gnuplot scale-2-comb-16g-point.plot && epstopdf scale-2-comb-16g.eps && rm -rf scale-2-comb-16g.eps


# Go to each scale directory
# 1. extract data from each job output, and save to *.dat file
# 2. compute average and save to scale-X-avg.dat file

declare -a bwsum
declare -a msg

#delta=32
#for s in 4 8 16 32 64 128 200 256 400 440 471; do # for allreduce
delta=32
for s in 2 4 8 16 32 64 128 213; do # for alltoall, 400, 440, 471 no data

    if [ -d "${LOG_PATH}-${s}" ]; then
        echo "Enter log dir ${LOG_PATH}-${s}"
    else
        echo "Log dir ${LOG_PATH}-${s} not exist"
        break
    fi

    echo "Extracting BW data from ${LOG_PATH}-${s} job output" 
    rm -rf ${LOG_PATH}-${s}/*.dat
    for f in $(ls ${LOG_PATH}-${s}/*.o*); do
        filename=$(basename $f)
        ln=$(grep -Fn 'Out of bounds values :' $f | cut -d ':' -f 1)
        stln=$(($ln-$delta))
        endln=$(($ln-1))
        sed -n "${stln},${endln}p" $f > ${LOG_PATH}-${s}/$filename.dat
        #add_msg_unit ${LOG_PATH}-${s}/$filename.dat
    done

    #sed "s/fillupscale/${s}/g" scale-all-lp.plot > scale-${s}-lp.plot
    #echo "Plotting with all scale-${s} BW data"
    #gnuplot scale-${s}-lp.plot && epstopdf scale-${s}.eps && rm -rf scale-${s}.eps


    echo "Calculating avgerage BW of each msg size of scale-${s}"
    fn=0
    for f in $(ls ${LOG_PATH}-${s}/*.dat); do
        ((fn++))
        for i in $(seq 1 $delta); do
            bw=$(sed -n "${i}p" $f | awk '{print $10}')
            if [ $fn -eq 1 ]; then
                msg[$i]=$(sed -n "${i}p" $f | awk '{print $1}')
                bwsum[$i]=$bw
            else
                bwsum[$i]=$(echo "scale=2; ${bwsum[$i]} + $bw" | bc -l)
            fi
        done
    done

    if [ -f "scale-${s}-bw-avg.dat" ]; then
        rm -rf scale-${s}-bw-avg.dat
    fi
    for i in $(seq 1 $delta); do
        bwavg=$(echo "scale=2; ${bwsum[$i]} / $fn" | bc -l)
        echo -e "${msg[$i]}\t${bwavg}" >> alltoall-scale-${s}-bw-avg.dat
    done
    #delta=$(($delta-1))

done

echo "Plotting with average BW of all scales"
gnuplot scale-all-avg-lp.plot && epstopdf scale-all-avg.eps && rm -rf scale-all-avg.eps



