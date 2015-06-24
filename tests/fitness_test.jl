@everywhere include("../src/EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

# create a random network
N = 20
generator = ev.SparseFRGenerator( N, topology = ev.MetaTopology(ev.AbstractTopology[ev.ErdösRenyiTopology()]) )

gopt = ev.GeneticOptimizer( ev.test_fitness_of_generator, ev.compare_fitness )

ev.init_population!(gopt, generator, 20)

for i = 1:100
  ev.step!(gopt)
  ev.save_evolution("genes.dat", gopt)
end

