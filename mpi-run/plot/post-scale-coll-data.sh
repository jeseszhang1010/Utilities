#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 <LOG_PATH> <BENCHMARK> <SCALES>"
    exit 1
fi


LOG_PATH=$1
BENCH=$2


# Go to each scale directory
# 1. extract data from each job output, and save to *.dat file
# 2. compute average and save to $BENCH-scale-X-lat-avg.dat file

declare -a latsum
declare -a msgo
declare -a scales

scales=($3)

for s in ${scales[@]}; do

    if [ -d "${LOG_PATH}/${s}-${BENCH}" ]; then
        echo "Enter log dir ${LOG_PATH}/${s}-${BENCH}"
    else
        echo "Log dir ${LOG_PATH}/${s}-${BENCH} not exist"
        break
    fi

    echo "Extracting BW data from ${LOG_PATH}/${s}-${BENCH} job output" 
    rm -rf ${LOG_PATH}/${s}-${BENCH}/*.dat
    for f in $(ls ${LOG_PATH}/${s}-${BENCH}/*.OU); do
        filename=$(basename $f)
	if [ "$BENCH" = "barrier" ]; then
            stln=$(grep -Fn '# Avg' $f | cut -d ':' -f 1)
        else
            stln=$(grep -Fn '# Size' $f | cut -d ':' -f 1)
        fi
	endln=$(grep -Fn 'Finish running' $f | cut -d ':' -f 1)
        stln=$(($stln+1))
        endln=$(($endln-1))
        sed -n "${stln},${endln}p" $f > ${LOG_PATH}/${s}-${BENCH}/$filename.dat
    done


    echo "Calculating avgerage of each msg size in ${s}-${BENCH}"
    fn=0
    for f in $(ls ${LOG_PATH}/${s}-${BENCH}/*.dat); do
        ((fn++))
	ttln=$(cat $f | wc -l)
	for i in $(seq 1 $ttln); do
	    if [ "$BENCH" = "barrier" ]; then
                lat=$(sed -n "${i}p" $f | awk '{print $1}')
            else
                lat=$(sed -n "${i}p" $f | awk '{print $2}')
	    fi
            if [ $fn -eq 1 ]; then
                latsum[$i]=$lat
	        if [ "$BENCH" != "barrier" ]; then
                    msg[$i]=$(sed -n "${i}p" $f | awk '{print $1}')
	        fi
            else
                latsum[$i]=$(echo "scale=2; ${latsum[$i]} + $lat" | bc -l)
            fi
        done
    done

    if [ -f "${BENCH}-scale-${s}-lat-avg.dat" ]; then
        rm -rf ${BENCH}-scale-${s}-lat-avg.dat
    fi
    for i in $(seq 1 $ttln); do
        latavg=$(echo "scale=2; ${latsum[$i]} / $fn" | bc -l)
	if [ "$BENCH" = "barrier" ]; then
            echo -e "${latavg}" >> ${BENCH}-scale-${s}-lat-avg.dat
	else
            echo -e "${msg[$i]}\t${latavg}" >> ${BENCH}-scale-${s}-lat-avg.dat
	fi
    done


done


cp scale-all-avg-lp.plot ${BENCH}-scale-all-avg-lp.plot
sed -i "s/BENCH/${BENCH}/g" ${BENCH}-scale-all-avg-lp.plot

for s in ${scales[@]}; do
    if [ ${s} -eq "${scales[-1]}" ]; then
        echo "    '${BENCH}-scale-${s}-lat-avg.dat' u 1:2 w lp title 'Scale=${s}'" >> ${BENCH}-scale-all-avg-lp.plot
    else
        echo "    '${BENCH}-scale-${s}-lat-avg.dat' u 1:2 w lp title 'Scale=${s}', \\" >> ${BENCH}-scale-all-avg-lp.plot
    fi
done

echo "Plotting with average lat of all scales"
gnuplot ${BENCH}-scale-all-avg-lp.plot && epstopdf ${BENCH}-scale-lat-avg.eps && rm -rf ${BENCH}-scale-lat-avg.eps ${BENCH}-scale-all-avg-lp.plot



