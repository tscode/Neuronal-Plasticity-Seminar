load 'pictures/presets.gp'

set terminal cairolatex size 9cm,16cm dashed color colortext transparent
set output 'pictures/freq_optimization.tex'

set lmargin 7
set rmargin 3

#unset xtics
set format x ''
#unset ytics

set xrange [0:100]
set grid xtics ls 100
set grid ytics ls 100

set key outside above
set multiplot

set tmargin scr 0.96
set bmargin scr 0.75
set yrange [0.6:1.8]
set ylabel '\textbf{(a)} Gain \gain'
plot 'data/high_frq_opt.dat' u 1:6 w d lt 1 notitle ,\
     'data/low_frq_opt.dat' u 1:6 w d lt 2 notitle ,\
     'data/high_frq_opt.dat' u 1:6 s u lt 1 lw 7 t '$C\ix{high}$', \
     'data/low_frq_opt.dat' u 1:6 s u lt 2 lw 7 t '$C\ix{low}$', \

set tmargin scr 0.73 
set bmargin scr 0.52
set yrange [0:18]
unset key
set ylabel '\textbf{(b)} Feedback \texttt{fb}'
plot 'data/high_frq_opt.dat' u 1:8 w d lt 1 t 'High', \
     'data/low_frq_opt.dat' u 1:8 w d lt 2 t 'Low',\
     'data/high_frq_opt.dat' u 1:8 s u lt 1 lw 7 t 'High', \
     'data/low_frq_opt.dat' u 1:8 s u lt 2 lw 7 t 'Low', \

set tmargin scr 0.50
set bmargin scr 0.29
set yrange [5:30]
unset key
set ylabel '\textbf{(c)} Probability $\ERprob$'

plot 'data/high_frq_opt.dat' u 1:($9*100) w d lt 1 t 'High', \
     'data/low_frq_opt.dat' u 1:($9*100) w d lt 2 t 'Low',\
     'data/high_frq_opt.dat' u 1:($9*100) s u lt 1 lw 7 t 'High', \
     'data/low_frq_opt.dat' u 1:($9*100) s u lt 2 lw 7 t 'Low', \

set tmargin scr 0.27
set bmargin scr 0.06
set yrange [0:1]
unset key
set ylabel '\textbf{(d)} Fitness $F_C$'
set format x "%.0f" 
set xlabel 'Generation'

plot 'data/high_frq_opt.dat' u 1:2 w d lt 1 t 'High', \
     'data/low_frq_opt.dat' u 1:2 w d lt 2 t 'Low',\
     'data/high_frq_opt.dat' u 1:2 s u lt 1 lw 7 t 'High', \
     'data/low_frq_opt.dat' u 1:2 s u lt 2 lw 7 t 'Low', \

unset multiplot
