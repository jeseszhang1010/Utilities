#!/bin/bash

HOSTFILE=${1:? "Usage: $0 <hostfile>"}

parallel-ssh -h $HOSTFILE -x "-o ConnectTimeout=5" -i -p128 "nohup bash -lc \"sudo systemctl restart mrc-config\" > /dev/null 2>&1 &"
