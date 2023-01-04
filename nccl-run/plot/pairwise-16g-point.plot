set terminal postscript eps color size 7,5
set out "pairwise-16g.eps"

set title "NCCL Allreduce BW at 16GB Message Size with all Two-Node Pairs" font "Helvetica,16"

set xlabel "Node Pair" offset 0,-0.5,0
set ylabel "BW (GB/s)"
set yrange [100:200]
set ytics 5
set xrange [0:250000]

unset key 
set grid

plot 'pairwise-16g.dat' using 1:3 with points 
