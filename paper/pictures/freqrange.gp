load 'pictures/presets.gp'

set terminal cairolatex size 9cm,6cm dashed color colortext transparent
set output 'pictures/freqrange.tex'

set yrange [-0.1 : 1.1]
set xrange [10**(-3) : 10**0.5]

set xlabel 'Frequency $\omega$'
set ylabel 'Fitness $F_{C(\omega)}$'
set grid
set style line 100 lt 5 lc rgb "gray" lw 2
set style line 101 lt 7 lc rgb "gray" lw 0.25

set grid mxtics xtics ls 100, ls 101

set key outside above 

set logscale x

plot 'data/freqrange_unoptimized.txt' w l lw 2 t 'Unoptimized',\
     'data/freqrange_high.txt'        w l lw 2 t 'High',\

