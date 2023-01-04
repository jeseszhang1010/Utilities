set terminal postscript eps color size 7,5
set out "scale-all-avg.eps"

# for allreduce
set title "NCCL Allreduce BW of Different Scales (avg)" font "Helvetica,16"

# for alltoall
#set title "NCCL Alltoall BW of Different Scales (avg)" font "Helvetica,16"

set xlabel "Message size (Byte)" offset 0,-1,0
set ylabel "BW (GB/s)"

set logscale x 2
set xrange [*:*]

# for alltoall, as different distinct group has different starting message size
#set xtics (64, 128, 256, 512, "1K" 1024, "2K" 2048, "4K" 4096, "8K" 8192, "16K" 16384, "32K" 32768,  "64K" 65536, "128K" 131072, "256K" 262144, "512K "524288, "1M" 1048576, "2M" 2097152, "4M" 4194304, "8M" 8388608, "16M" 16777216, "32M" 33554432, "64M" 67108864, "128M" 134217728, "256M" 268435456, "512M "536870912, "1G" 1073741824, "2G" 2147483648, "4G" 4294967296, "8G" 8589934592, "16G" 17179869184)

# for allreduce
set xtics (8, 16, 32, 64, 128, 256, 512, "1K" 1024, "2K" 2048, 4096 "4K", "8K" 8192, "16K" 16384, "32K" 32768,  "64K" 65536, "128K" 131072, "256K" 262144, "512K "524288, "1M" 1048576, "2M" 2097152, "4M" 4194304, "8M" 8388608, "16M" 16777216, "32M" 33554432, "64M" 67108864, "128M" 134217728, "256M" 268435456, "512M "536870912, "1G" 1073741824, "2G" 2147483648, "4G" 4294967296, "8G" 8589934592, "16G" 17179869184)

set xtics rotate by -45 autojustify

set key left top
set grid

# for allreduce
plot 'allreduce-scale-4-bw-avg.dat' u 1:2:xtic(1) w lp title 'Scale=4', \
     'allreduce-scale-8-bw-avg.dat' u 1:2:xtic(1) w lp title 'Scale=8', \
     'allreduce-scale-16-bw-avg.dat' u 1:2:xtic(1) w lp title 'Scale=16', \
     'allreduce-scale-32-bw-avg.dat' u 1:2:xtic(1) w lp title 'Scale=32', \
     'allreduce-scale-64-bw-avg.dat' u 1:2:xtic(1) w lp title 'Scale=64', \
     'allreduce-scale-128-bw-avg.dat' u 1:2:xtic(1) w lp title 'Scale=128', \
     'allreduce-scale-256-bw-avg.dat' u 1:2:xtic(1) w lp title 'Scale=256',\
     'allreduce-scale-276-bw-avg.dat' u 1:2:xtic(1) w lp title 'Scale=276'


# for alltoall
#plot 'alltoall-scale-4-bw-avg.dat' u 1:2 w lp title 'Scale=4', \
#     'alltoall-scale-8-bw-avg.dat' u 1:2 w lp title 'Scale=8', \
#     'alltoall-scale-16-bw-avg.dat' u 1:2 w lp title 'Scale=16', \
#     'alltoall-scale-32-bw-avg.dat' u 1:2 w lp title 'Scale=32', \
#     'alltoall-scale-64-bw-avg.dat' u 1:2 w lp title 'Scale=64', \
#     'alltoall-scale-128-bw-avg.dat' u 1:2 w lp title 'Scale=128', \
#     'alltoall-scale-256-bw-avg.dat' u 1:2 w lp title 'Scale=256'
