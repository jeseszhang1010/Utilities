#!/bin/bash

set -e

join_arr() {
  local IFS="$1"
  shift
  echo "$*"
}

HOSTFILE=${1:?"usage: $0 <hostfile> <num_racks>"}
NUM_RACKS=${2:?"usage: $0 <hostfile> <num_racks>"}
FROOT=$(echo "$HOSTFILE" | cut -d. -f1)
HOSTNAME_IP_FILE=$FROOT-hostname_ip

echo "... gen hostname ip ..."
./gen-hostname-ip.sh $HOSTFILE $HOSTNAME_IP_FILE
echo "... setup mnnvl mrc ..."
./setup-mnnvl-by-pc-by-row.sh $HOSTNAME_IP_FILE $NUM_RACKS
#./setup-mnnvl-nccl-mrc.sh $HOSTNAME_IP_FILE $NUM_RACKS
FINAL_IP_FILE="ips-for-nccl-$HOSTNAME_IP_FILE"
FINAL_HOSTNAME_FILE="hosts-for-grok-$HOSTNAME_IP_FILE"

exit 0

(module load mpi/hpcx; \
mpirun -np $((NUM_RACKS*16)) \
  --allow-run-as-root \
  -mca plm_rsh_no_tree_spawn 1 -mca plm_rsh_num_concurrent 8192 \
  --map-by ppr:4:node --bind-to none \
  --hostfile $FINAL_IP_FILE \
   -x UCX_TLS=tcp \
  -x LD_LIBRARY_PATH \
  -mca coll_hcoll_enable 0 \
  --mca btl tcp,vader,self \
  --mca pml ob1 \
  --mca btl_tcp_if_include enP22p1s0f1 hostname 2>&1 | tee mpirun-sanity-$HOSTFILE)
 
HOSTFILE=$FINAL_IP_FILE ./run-nccl-shim.sh $((NUM_RACKS*16)) sendrecv 2>&1 | tee nccl-check-mrc-only-$HOSTFILE
HOSTFILE=$FINAL_IP_FILE ./run-nccl-shim-mnnvl.sh $((NUM_RACKS*16)) all_gather 2>&1 | tee nccl-check-mrc-mnnvl-$HOSTFILE

mapfile -t HOSTNAME_ARR < <(cat $FINAL_HOSTNAME_FILE | sed 's/^$//g')

SCTRL_OUT=$(scontrol show node $(join_arr , "${HOSTNAME_ARR[@]}"))

#sinfo -N -h -p debug -t idle -o "%N" > all_idle_nodes-$HOSTFILE
#grep -Fxv -f all_idle_nodes-$HOSTFILE <(cat $FINAL_HOSTNAME_FILE | sed 's/^$//g') 
NUM_NODES_IN_IDLE=$(echo "$SCTRL_OUT" | grep 'State=IDLE ' | wc -l)
echo "$NUM_NODES_IN_IDLE/$((16*NUM_RACKS)) are in IDLE state"

grep -Fxvf <(sinfo -N -h -t idle -o "%N") $FINAL_HOSTNAME_FILE
