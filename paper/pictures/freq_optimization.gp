load 'pictures/presets.gp'

set terminal cairolatex size 9cm,12cm dashed color colortext transparent
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

set tmargin scr 0.95
set bmargin scr 0.69
set yrange [0.6:1.8]
set ylabel 'Gain'
plot 'data/high_frq_opt.dat' u 1:6 w d lt 1 notitle ,\
     'data/full_frq_opt.dat' u 1:6 w d lt 3 notitle 'Full',\
     'data/low_frq_opt.dat' u 1:6 w d lt 2 notitle 'Low',\
     'data/high_frq_opt.dat' u 1:6 s u lt 1 lw 7 t 'High', \
     'data/low_frq_opt.dat' u 1:6 s u lt 2 lw 7 t 'Low', \
     'data/full_frq_opt.dat' u 1:6 s u lt 3 lw 7 t 'Full', \

set tmargin scr 0.65 
set bmargin scr 0.38
set yrange [0:17]
unset key
set ylabel 'Feedback'
plot 'data/high_frq_opt.dat' u 1:8 w d lt 1 t 'High', \
     'data/low_frq_opt.dat' u 1:8 w d lt 2 t 'Low',\
     'data/full_frq_opt.dat' u 1:8 w d lt 3 t 'Low',\
     'data/high_frq_opt.dat' u 1:8 s u lt 1 lw 7 t 'High', \
     'data/low_frq_opt.dat' u 1:8 s u lt 2 lw 7 t 'Low', \
     'data/full_frq_opt.dat' u 1:8 s u lt 3 lw 7 t 'Low', \

set tmargin scr 0.34
set bmargin scr 0.08
set yrange [5:30]
unset key
set ylabel 'Probability'
set format x "%.0f" 
set xlabel 'Generation'

plot 'data/high_frq_opt.dat' u 1:($9*100) w d lt 1 t 'High', \
     'data/low_frq_opt.dat' u 1:($9*100) w d lt 2 t 'Low',\
     'data/full_frq_opt.dat' u 1:($9*100) w d lt 3 t 'Low',\
     'data/high_frq_opt.dat' u 1:($9*100) s u lt 1 lw 7 t 'High', \
     'data/low_frq_opt.dat' u 1:($9*100) s u lt 2 lw 7 t 'Low', \
     'data/full_frq_opt.dat' u 1:($9*100) s u lt 3 lw 7 t 'Low', \

unset multiplot
