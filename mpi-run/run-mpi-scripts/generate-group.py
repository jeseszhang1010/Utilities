#!/usr/bin/python3
import sys
import random
from itertools import combinations

argc = len(sys.argv)
if argc != 3:
    print("incorrect usage: ", sys.argv[0], " <scale> <hostfile>")
    sys.exit(-1)

scale = sys.argv[1]
hostfile = sys.argv[2]
hostlistx = list()

with open(hostfile, 'r') as fp:
    for count, line in enumerate(fp):
        pass
ln = count + 1

rem = int(ln) % int(scale)

with open(hostfile) as file:
    for line in file:
        hostlistx.append(line.strip() + ":ppn=176")

hostlist = list()
for i in range(0,int(ln)-rem,int(scale)):
    hostlist.append("+".join(hostlistx[i:i+int(scale)]))


for g in hostlist:
    print(g)
