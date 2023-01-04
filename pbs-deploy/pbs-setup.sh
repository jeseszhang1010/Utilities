#!/bin/bash
set -e

function help_msg {
    echo "Usage: $0 <hostfile> <head-node-name>"
    echo "Also note that it's required to be able to passwordless ssh across headnode and all compute nodes"
    exit -1
}

if [ $# -ne 2 ]; then
    help_msg
fi

HOSTLIST=$1
HEADNODE=$2 

if [ ${HEADNODE} != "$(hostname)" ]; then
    echo "This script is required to be run on head node $HEADNODE $(hostname)"
    help_msg
fi

if [ ! $(which parallel-ssh) ]; then
    echo "No required pssh package"
    help_msg
fi

# Install PBS on head node
./pbs-install.sh server $HEADNODE

# Install PBS on all compute nodes
parallel-rsync -h $HOSTLIST -av ./v22.05.11.tar.gz  $HOME/
parallel-rsync -h $HOSTLIST -av  ./pbs-install.sh  $HOME/
parallel-ssh -h $HOSTLIST  -t 1800  -i  $HOME/pbs-install.sh client $HEADNODE

# Add compute node into pbs cluster 
for cn in $(cat $HOSTLIST); do
    sudo /opt/pbs/bin/qmgr -c "create node $cn"
done

# check all nodes are in free state
