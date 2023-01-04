#!/bin/bash

# This script assumes the pbs output files (*.OU)
# are placed under ${LOG_PATH}-{scale},
# e.g.,
# all 2 nodes output (*.OU) are placed under ${LOG_PATH}-2.
# all 4 nodes output (*.OU) are placed under ${LOG_PATH}-4.
# Thus, set the variable LOG_PATH based on your layout.
# 

if [ $# -ne "1" ]; then
    echo "Usage: $0 <LOGPATH>"
    exit 1
fi
LOG_PATH=$1

#msgunit=(4 8 16 32 64 128 256 512 1K 2K 4K 8K 16K 32K 64K 128K 256K 512K 1M 2M 4M 8M 16M 32M 64M 128M 256M 512M 1G 2G 4G 8G 16G)
msgunit=(64 128 256 512 1K 2K 4K 8K 16K 32K 64K 128K 256K 512K 1M 2M 4M 8M 16M 32M 64M 128M 256M 512M 1G 2G 4G 8G 16G)

add_msg_unit() {
    local fn=$1
    for l in $(seq 1 32); do
        sed -i "$l s/^/${msgunit[$l]}\t/" $fn
    done
}


# Go to each scale directory
# 1. extract data from each job output, and save to *.dat file
# 2. compute average and save to scale-X-avg.dat file

declare -a bwsum
declare -a msg

delta=32
if [ "$proto" = "ll" ]; then
    delta=28
fi

for s in 4 8 16 32 64 128 256 512 699; do # for alltoall, 400, 440, 471 no data

    if [ -d "${LOG_PATH}-${s}" ]; then
        echo "Enter log dir ${LOG_PATH}-${s}"
    else
        echo "Log dir ${LOG_PATH}-${s} not exist"
        break
    fi

    echo "Extracting BW data from ${LOG_PATH}-${s} job output" 
    rm -rf ${LOG_PATH}-${s}/*.dat
    for f in $(ls ${LOG_PATH}-${s}/*.OU); do
        filename=$(basename $f)
        echo $filename
        ln=$(grep -Fn 'Out of bounds values :' $f | cut -d ':' -f 1)
        stln=$(($ln-$delta))
        endln=$(($ln-1))
        sed -n "${stln},${endln}p" $f > ${LOG_PATH}-${s}/$filename.dat
    done

    #sed "s/fillupscale/${s}/g" scale-all-lp.plot > scale-${s}-lp.plot
    #echo "Plotting with all scale-${s} BW data"
    #gnuplot scale-${s}-lp.plot && epstopdf scale-${s}.eps && rm -rf scale-${s}.eps


    echo "Calculating avgerage BW of each msg size of scale-${s}"
    fn=0
    for f in $(ls ${LOG_PATH}-${s}/*.dat); do
        ((fn++))
        for i in $(seq 1 $delta); do
            bw=$(sed -n "${i}p" $f | awk '{print $12}')
            if [ $fn -eq 1 ]; then
                msg[$i]=$(sed -n "${i}p" $f | awk '{print $1}')
                bwsum[$i]=$bw
            else
                bwsum[$i]=$(echo "scale=2; ${bwsum[$i]} + $bw" | bc -l)
            fi
        done
    done
    
    bw_avg_fname="alltoall-scale-$s-bw-avg.dat"

    if [ -f "$bw_avg_fname" ]; then
        rm -rf $bw_avg_fname 
    fi
    for i in $(seq 1 $delta); do
        bwavg=$(echo "scale=2; ${bwsum[$i]} / $fn" | bc -l)
        echo -e "${msg[$i]}\t${bwavg}" >> $bw_avg_fname
    done

done

echo "Plotting with average BW of all scales"
#gnuplot alltoall-scale-all-avg-lp.plot && epstopdf alltoall-scale-all-avg.eps && rm -rf alltoall-scale-all-avg.eps



