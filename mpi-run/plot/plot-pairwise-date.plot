set terminal postscript eps color size 7,5
#set out "pairwise-180-lat-1B.eps"
set out "pairwise-180-bw-8MB.eps"
#set out "pairwise-180-bibw-8MB.eps"

set title "OSU Bandwidth at 8MB Message Size with all Two-Node Pairs" font "Helvetica,16"

set xlabel "Node Pair" offset 0,-0.5,0
#set ylabel "Latency (us)"
set ylabel "BW (Gbps)"
set yrange [0:400]
#set yrange [0:3]
set ytics 20 
set xrange [0:17000]

unset key 
set grid

plot 'pairwise-180-bw-8MB.dat' using 1:3 with points 
