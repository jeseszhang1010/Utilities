#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <LOG_PATH> <PAIRWISE_TAG>"
    exit 1
fi

LOG_PATH=$1
PAIRWISE_TAG=pairwise-$2


# Go to $LOG_PATH directory,
# extract pairwise data from all job output,
# save to $PAIRWISE_TAG


if [ -f "$PAIRWISE_TAG.dat" ]; then
    rm -rf $PAIRWISE_TAG.dat
fi

echo "Extracting allpairs data to generate $PAIRWISE_TAG"
line=0
for f in $(find ${LOG_PATH} -type f -name '*.OU'); do
    line=$(($line+1))
    if [[ "$2" == *"lat"* ]]; then
        value=$(grep -m1 "^1" $f | awk '{print $2}')
    elif [[ "$2" == *"bw"* ]]; then
        value=$(grep -m1 "^8388608" $f | awk '{print $2}')
        bwGbps=$(echo "scale=2; $value * 8 / 1024" | bc -l)
    else
	echo "Invalid tag, it can be lat, bw or bibw only"
	exit 1
    fi
    echo -e "$line\t${f}\t$bwGbps" >> $PAIRWISE_TAG.dat
done

#gnuplot plot-pairwise-date.plot && epstopdf pairwise-lat-1byte.eps && rm -rf *.eps

