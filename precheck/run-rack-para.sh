#!/bin/bash
#

HOMEDIR=/home/azhpcuser/zhanj

pushd $HOMEDIR/precheck
rm -rf hostfile-per-rack.txt
allracks=$(ls hostfile-F01C02C022-*-nvl64)
for r in $allracks; do
    head -1 $r >> hostfile-per-rack.txt
done
popd

parallel-ssh -h $HOMEDIR/precheck/hostfile-per-rack.txt -t180 -i "cd $HOMEDIR/precheck && ./run-rack-each.sh"
