set terminal postscript eps color size 7,5
set out "BENCH-scale-lat-avg.eps"

set title "OMB BENCH Latency of Different Scales (avg)" font "Helvetica,16"

set xlabel "Message size (Byte)" offset 0,-1,0
set ylabel "Latency (us)"

set logscale x 2
set logscale y 10
set xrange [*:*]


set xtics (4, 8, 16, 32, 64, 128, 256, 512, "1K" 1024, "2K" 2048, "4K" 4096, "8K" 8192, "16K" 16384, "32K" 32768,  "64K" 65536, "128K" 131072, "256K" 262144, "512K "524288, "1M" 1048576, "2M" 2097152, "4M" 4194304, "8M" 8388608, "16M" 16777216, "32M" 33554432)

set xtics rotate by -45 autojustify

set key left top
set grid

# post-scale-coll-data.sh will add the following dat files according to
# different scales provided 
#     'BENCH-scale-4-lat-avg.dat' u 1:2 w lp title 'Scale=4', \
#     'BENCH-scale-8-lat-avg.dat' u 1:2 w lp title 'Scale=8', \
#     'BENCH-scale-16-lat-avg.dat' u 1:2 w lp title 'Scale=16'

plot \
