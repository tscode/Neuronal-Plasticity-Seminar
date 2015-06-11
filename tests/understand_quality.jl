include("../src/EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

N = 10

f(t) = cos(t) + 0.5sin(3t)
g(t) = 0
task = ev.FunctionTask( [f;], [g;] )

quals = Float64[]
rule  = ev.ForceRule( N, 1 )

generator = ev.SparseMatrixGenerator( N, 0.1, gain = 1.1  )
for i in 1:10
    net = ev.generate( generator, i )
    push!( quals, ev.test_fitness_for_task(net, rule, task, 
           learntime = 500, evaltime = 1000, waittime =  200, α=1/1000,
           fname="understand_$i.dat")[1] )
end
