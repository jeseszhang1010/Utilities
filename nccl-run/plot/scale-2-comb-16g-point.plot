set terminal postscript eps color size 7,5
set out "scale-2-comb-8g.eps"

set title "NCCL Alltoall BW at 8GB Message Size with all Two-Node Pairs" font "Helvetica,16"

set xlabel "Node Pair" offset 0,-0.5,0
set ylabel "BW (GB/s)"
set yrange [10:50]
set ytics 5
set xrange [0:111000]

unset key 
set grid

plot 'scale-2-comb-8g.dat' using 1:3 with points 
