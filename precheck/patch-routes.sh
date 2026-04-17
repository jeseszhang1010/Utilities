#!/bin/bash

HOSTFILE=${1:? "Usage: $0 <hostfile> <source-mrc-config>"}

MRC_SCRATCH_REMOTE=/home/azhpcuser/mrc-config-scratch

set -x
parallel-ssh -h $HOSTFILE -x "-o ConnectTimeout=5" -i -p128 "rm -rf $MRC_SCRATCH_REMOTE; mkdir -p $MRC_SCRATCH_REMOTE"
parallel-scp -h $HOSTFILE -x "-o ConnectTimeout=5" -p128 "run-doca-services.sh" "config_routes.py" "$MRC_SCRATCH_REMOTE"
parallel-ssh -h $HOSTFILE -x "-o ConnectTimeout=5" -i -p128 "cd $MRC_SCRATCH_REMOTE/; sudo cp -r ./* /opt/microsoft/mrc/config/; rm -rf $MRC_SCRATCH_REMOTE"
