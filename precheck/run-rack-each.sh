#!/bin/bash
#

HOMEDIR=/home/azhpcuser/zhanj
pushd $HOMEDIR/precheck
hf=$(grep "$(hostname)" hostnames-F01C02C022-*-nvl64 | cut -d- -f2-3)
hf=hostfile-$hf-nvl64
echo $hf

#echo "#### Run shim layer $hf #####"
#HOSTFILE=$HOMEDIR/precheck/$hf ./run-nccl-shim.sh 16 sendrecv 2>&1 | tee $HOMEDIR/nccl-shim-16nodes-rack-$hf-sendrecv.log
#HOSTFILE=$HOMEDIR/precheck/$hf ./run-nccl-shim-mnnvl.sh 16 all_gather 2>&1 | tee nccl-shim-mnvnl-16nodes-rack-$hf-allgather.log

echo "#### Run mrc nccl plugin $hf ####"
nodecnt=$(wc -l $hf | awk '{print $1}')
rm -rf  $HOMEDIR/nccl-mrc-plugin-mnvnl-rack-$hf-allreduce.log
#HOSTFILE=$HOMEDIR/precheck/$hf ./run-nccl-mrc-plugin.sh 16 sendrecv 2>&1 | tee $HOMEDIR/nccl-mrc-plugin-16nodes-rack-$hf-sendrecv.log
HOSTFILE=$HOMEDIR/precheck/$hf ./run-nccl-mrc-plugin-mnnvl.sh $nodecnt all_reduce 2>&1 | tee $HOMEDIR/nccl-mrc-plugin-mnvnl-rack-$hf-allreduce.log
#
popd

for i in 1 2 3; do
  scp $HOMEDIR/precheck/nccl-mrc-plugin-mnvnl-rack-$hf-allreduce.log 180.21.16.10:/home/azhpcuser/zhanj/atl21-pc22-run/ && break
  #scp  $HOMEDIR/*-$hf-*.log  170.7.0.13:/home/azhpcuser/zhanj/atl21-pc22-run/
  echo "scp failed (attempt $i/3), retrying in 5s..."
  sleep 5
done
