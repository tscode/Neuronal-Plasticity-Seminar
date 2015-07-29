
using EvoNet
ev = EvoNet
# create a random network
N = 15
p = 0.1
ertop = ev.ErdösRenyiTopology(p)
#=ritop = ev.RingTopology(2.4)=#
#=fftop = ev.FeedForwardTopology([0.2, 0.5, 0.3, 0.1])=#
#=cotop = ev.CommunityTopology([0.2, 0.5, 0.3, 0.3], 0.05, 0.2)=#

#=top = ev.MetaTopology( ev.AbstractTopology[ ertop, ritop, fftop, cotop ], p = [0.25, 0.25, 0.25, 0.25] )=#
ch   = ev.complex_wave(n = 1)
env  = ev.Environment(challenge=ch, blacklist=["size"])
gopt = ev.GeneticOptimizer( ev.fitness_in_environment, ev.compare_fitness, env=env )

gen  = ev.SparseFRGenerator( N, topology = ertop )
ev.init_population!(gopt, gen, 10)

for p in ev.export_params(gen)
    println(p.name)
end

for i = 1:25
  ev.step!(gopt)
  ev.save_evolution("genes_top.dat", gopt)
end

