#!/bin/bash

HOSTFILE=${1:?"Usage $0 <hostfile> <hostnameip file>"}
HOSTNAME_IP_FILE=${2:?"Usage $0 <hostfile> <hostnameip file>"}

NUM_NODES=$(wc -l < $HOSTFILE)
PSSH_OUT=$(parallel-ssh -h $HOSTFILE -i -p 128 -x "-o ConnectTimeout=5" "echo \"\$HOSTNAME,\$(ip -br addr show | grep enP22 | awk '{print \$3}' | cut -d/ -f1)\" ")
HOSTNAME_IP=$(echo "$PSSH_OUT" | grep ATL)
echo "$HOSTNAME_IP" > $HOSTNAME_IP_FILE
NUM_NODES_HOSTNAME_IP=$(wc -l < $HOSTNAME_IP_FILE)

echo "NUM_NODES=$NUM_NODES,NUM_NODES_HOSTNAME_IP=$NUM_NODES_HOSTNAME_IP"

echo "$PSSH_OUT" | grep -i failure


if [[ "$NUM_NODES" != "$NUM_NODES_HOSTNAME_IP" ]]; then
	echo "Removing the failure nodes from the hostfile"
	cat $HOSTNAME_IP_FILE | cut -d, -f2 > $HOSTFILE
fi

