#!/bin/bash

mapfile -t RACKS < <(ls nccl-shim-16nodes-rack-hostfile-F01C02C017-*.log | cut -d- -f7)

for rk in ${RACKS[@]}; do
    echo $rk
    python3 plot.py "nccl-*-16nodes-rack-hostfile-F01C02C017-$rk-sendrecv.log" 16nodes-F01C02C017-$rk-sendrecv-shim-vs-mrc-plugin
done