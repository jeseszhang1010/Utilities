#!/bin/bash


if [ $# -ne 2 ]; then
    echo "Invalid usage: $0 <compute-hostfile> <pbs-server>"
    exit -1
fi

HOSTFILE=$1
SERVER=$2

parallel-scp -h ${HOSTFILE} ./pbsclient.sh /tmp/
parallel-scp -h ${HOSTFILE} ./pbsdownload.sh /tmp/

parallel-ssh -h ${HOSTFILE} "sudo rm -rf ~/openpbs* && sudo /tmp/pbsdownload.sh"
parallel-ssh -t 300 -h ${HOSTFILE} "sudo /tmp/pbsclient.sh ${SERVER}"

