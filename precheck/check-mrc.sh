#!/bin/bash

HOSTFILE=${1:? "Usage: $0 <hostfile>"}

parallel-ssh -h $HOSTFILE -x "-o ConnectTimeout=5 -o StrictHostKeyChecking=no" -i -p128 "bash -lc \"sudo systemctl is-active mrc-config\""
