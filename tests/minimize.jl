
include("../src/EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

# create a random network
# init quantities
# Function for the task
f(t) = cos(t) + 0.5sin(3t)
g(t) = 0
task = ev.FunctionTask( [f;], [g;] )

trials = 25
@rec N avg min max for N in 10:50
    generator = ev.SparseMatrixGenerator( N, 0.1, gain = 1.4  )
    rule    = ev.ForceRule( N, 1 )
    avg = 0
    max = -Inf
    min = Inf
    for i in 1:trials
        net     = ev.generate( generator, i )
        quality = ev.test_fitness_for_task(net, rule, task, learntime = 500, evaltime = 1000)[1]
        avg += quality
        max = quality > max ? quality : max
        #=best_net = quality > max ? net : best_net=#
        min = quality < min ? quality : min
    end
    avg /= trials
    println("N = $N, avg = $avg, min = $min, max = $max")
end

writedlm("minimize2.dat", [ ev.REC[1] ev.REC[2] ev.REC[3] ev.REC[4] ])
