#!/bin/bash
HOSTFILE="${1:?Usage: $0 HOSTFILE N}"
N="${2:-10}"
shuf -n $N "$HOSTFILE"
