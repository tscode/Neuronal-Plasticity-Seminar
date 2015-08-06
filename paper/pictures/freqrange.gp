load 'pictures/presets.gp'

set terminal cairolatex size 9cm,6cm dashed color colortext transparent
set output 'pictures/freqrange.tex'

set yrange [-0.1 : 1.1]
set xrange [10**(-3) : 10**0.5]

set xlabel 'Frequency $\omega$'
set ylabel 'Fitness $F_{C_\omega}$'
set grid

set grid mxtics xtics ls 100, ls 101

set key outside above 

set logscale x

plot 'data/freqrange_unoptimized.txt' w l lt 3 lw 3 t '$G_{0}$',\
     'data/freqrange_high.txt'        w l lt 1 lw 3 t '$G\ix{high}$',\
     'data/freqrange_low.txt'         w l lt 2 lw 3 t '$G\ix{low}$',\

