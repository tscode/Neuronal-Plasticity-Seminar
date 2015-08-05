load 'pictures/presets.gp'

set terminal cairolatex size 9cm,16cm dashed color colortext transparent
set output 'pictures/freq_optimization.tex'

plot 'data/high_frq_opt.dat' w p t 'High', \

