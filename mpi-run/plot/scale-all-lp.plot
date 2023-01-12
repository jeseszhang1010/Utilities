set terminal postscript eps color size 7,5
set out "scale-fillupscale.eps"

set title "NCCL BW of scale fillupscale"

set xlabel "Message size (Byte)" offset 0,-1,0
set ylabel "BW (GB/s)"

set logscale x 2
set xrange [*:*]
set xtics font ",14" rotate by -45 autojustify

unset key
set grid


files=system("echo $(ls /home/jijos/zhanj/plot/final/allreduce/distinct-groups/nccl-allred-fillupscale/*.dat)")
plot for [f in files] f u 2:12:xtic(1) w lp title f

