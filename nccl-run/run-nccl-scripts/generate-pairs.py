#!/usr/bin/python3
import sys
import random
from itertools import combinations

argc = len(sys.argv)
if argc != 2:
    print("incorrect usage: ", sys.argv[0], " <hostfile>\n")
    sys.exit(-1)


hostlistx = open(sys.argv[1]).read().splitlines()
hostlist = (h + ":ppn=96" for h in hostlistx)

outlist = ["+".join(map(str, comb)) for comb in combinations(hostlist, 2)]
random.shuffle(outlist)

#print outlist

for comb in outlist:
    print(comb)

