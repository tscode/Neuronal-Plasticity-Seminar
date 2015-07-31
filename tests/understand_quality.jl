#=include("../src/EvoNet.jl")=#
using EvoNet
ev = EvoNet

N = 100

ch = ev.simple_wave(n=1, amplitude=1, frequency=0.314/2pi, offset=0, phase=0)
task = ev.get_task(ch)


quals = Float64[]
rule  = ev.Learning.ForceRule( N, α=1/100 )

ertop = ev.ErdösRenyiTopology(0.1)
generator = ev.SparseFRGenerator( N, topology=ertop )


net = ev.generate( generator, seed=ev.randseed() )
ev.test_fitness_for_task(net, rule, task, fname="simu.dat")

#=for i in 1:10=#
    #=net = ev.generate( generator, i )=#
    #=push!( quals, ev.test_fitness_for_task(net, rule, task, =#
           #=learntime = 500, evaltime = 1000, waittime =  200, α=1/1000,=#
           #=fname="")[1] )=#
#=end=#
