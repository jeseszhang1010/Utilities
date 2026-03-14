#!/bin/bash

if [ $# -ne 1 ];then
    echo "Usage $0 [benchmark]"
fi

maxscale=752
scale=2
benchmark=$1
outputs=()

# All scales of plugin run in one plot
python3 plot.py "mrc-plugin-${benchmark}-scale-*.log" ${benchmark}-allscales $benchmark
outputs+=("${benchmark}-allscales.pdf")

# Each scale plot with plugin and shim layer
while [[ $scale -le $maxscale ]]; do
    echo "# Plot scale $scale #"
    python3 plot.py "mrc-*-${benchmark}-scale-${scale}.log" ${benchmark}-scale-${scale} $benchmark
    outputs+=("${benchmark}-scale-${scale}.pdf")
    
    if [[ $scale -eq $maxscale ]]; then
	break
    fi

    scale=$((scale * 2))
    if [[ $scale -gt $maxscale ]]; then
        scale=$maxscale
    fi
done
pdfunite "${outputs[@]}" "${benchmark}-allinone.pdf"
