
include("../src/EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

# create a random network
# init quantities
# Function for the task
f(t) = cos(t) + 0.5sin(3t)
g(t) = 0
task    = ev.FunctionTask( [f;], [g;] )

trials = 1000
@rec N quality for N in 10:50
    generator = ev.SparseMatrixGenerator( N, 0.1, gain = 1.1  )
    rule    = ev.ForceRule( N, 1 )
    quality = 0
    for i in 1:trials
        net     = ev.generate( generator, i )
        quality += ev.test_fitness_for_task(net, rule, task, learntime = 500, evaltime = 500)[1]
    end
    quality /= trials
    println("N = $N, quality = $quality")
end

writedlm("minimize.dat", [ ev.REC[1] ev.REC[2] ])
