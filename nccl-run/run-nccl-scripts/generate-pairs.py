#!/usr/bin/python3
import sys
import random
from itertools import combinations

argc = len(sys.argv)
if argc != 3:
    print("incorrect usage: ", sys.argv[0], " <scale> <hostfile>")
    sys.exit(-1)

scale = sys.argv[1]
hostlistx = open(sys.argv[2]).read().splitlines()
hostlist = (h + ":ppn=96" for h in hostlistx)

# scale
#outlist = ["+".join(map(str, comb)) for comb in combinations(hostlist, 2)]
group = hostlist[0:3]
print(group)


# pair-wise
#outlist = ["+".join(map(str, comb)) for comb in combinations(hostlist, 2)]
#random.shuffle(outlist)

#print outlist

#for comb in outlist:
#    print(comb)

