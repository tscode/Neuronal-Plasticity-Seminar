@everywhere include("../src/EvoNet.jl")
ev = EvoNet
using EvoNet.optimize
@ev.optimize.MakeMeta(MetaTopology, ev.AbstractTopology)
@ev.optimize.MakeMetaGen(MetaTopology, generate)


# create a random network
N = 20
generator = EvoNet.SparseFRGenerator( N, topology = MetaTopology(EvoNet.AbstractTopology[EvoNet.ErdösRenyiTopology(), EvoNet.RingTopology()]) )
gopt = AnnealingOptimizer{EvoNet.SparseLRGenerator}( generator, EvoNet.test_fitness_of_generator )

set_callback!(gopt, (x,i)->println(i))

anneal(gopt, 20, itemp=1, ftemp = 0.001)

writedlm("res.txt", hcat(gopt.recorder[1], gopt.recorder[2], gopt.recorder[3]))
