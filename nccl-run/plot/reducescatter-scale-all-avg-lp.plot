set terminal postscript eps color size 7,5
set out "reducescatter-scale-all-avg.eps"

# for reducescatter
set title "NCCL ReduceScatter BW of Different Scales (avg)" font "Helvetica,16"


set xlabel "Message size (Byte)" offset 0,-1,0
set ylabel "BW (GB/s)"

set logscale x 2
set xrange [*:*]

# for reducescatter
set xtics (8, 16, 32, 64, 128, 256, 512, "1K" 1024, "2K" 2048, 4096 "4K", "8K" 8192, "16K" 16384, "32K" 32768,  "64K" 65536, "128K" 131072, "256K" 262144, "512K "524288, "1M" 1048576, "2M" 2097152, "4M" 4194304, "8M" 8388608, "16M" 16777216, "32M" 33554432, "64M" 67108864, "128M" 134217728, "256M" 268435456, "512M "536870912, "1G" 1073741824, "2G" 2147483648, "4G" 4294967296, "8G" 8589934592, "16G" 17179869184)

set xtics rotate by -45 autojustify

set key left top
set grid

# for reducescatter
plot 'reducescatter-scale-4-bw-avg.dat' u 2:3 w lp title 'Scale=4', \
     'reducescatter-scale-8-bw-avg.dat' u 2:3 w lp title 'Scale=8', \
     'reducescatter-scale-16-bw-avg.dat' u 2:3 w lp title 'Scale=16', \
     'reducescatter-scale-32-bw-avg.dat' u 2:3 w lp title 'Scale=32', \
     'reducescatter-scale-64-bw-avg.dat' u 2:3 w lp title 'Scale=64', \
     'reducescatter-scale-128-bw-avg.dat' u 2:3 w lp title 'Scale=128', \
     'reducescatter-scale-256-bw-avg.dat' u 2:3 w lp title 'Scale=256',\
     'reducescatter-scale-276-bw-avg.dat' u 2:3 w lp title 'Scale=276'


