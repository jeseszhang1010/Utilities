set terminal postscript eps color size 7,5
set out "scale-2-topo-aware-16g.eps"

set title "NCCL Allreduce BW at 16GB Message Size with Distinct Two-Node Pairs of Different Distances" font "Helvetica,16"

set xlabel "Node Pair" offset 0,-1,0
set ylabel "BW (GB/s)"
set xrange [0:205]
set yrange [170:200]
set ytics 5
#unset key 
set grid


plot 'nccl-allred-2-dist-2.dat' u 1:3 w point pointtype 3 lc 1 title 'Distance=2', \
     'nccl-allred-2-dist-4.dat' u 1:3 w point pointtype 2 lc 2 title 'Distance=4', \
     'nccl-allred-2-dist-6.dat' u 1:3 w point pointtype 1 lc 4 title 'Distance=6' 


