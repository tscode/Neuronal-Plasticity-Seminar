
include("EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

# create a random network
N = 2000
generator = ev.SparseMatrixGenerator( N, 0.1, gain = 1.1  )
# init quantities
# Function for the task
f(t) = cos(1.1t) + 0.5sin(1.3t)

n = 10000
# The types needed for the simulation
task    = ev.FunctionTask( [f] )
net     = ev.generate( generator, 1 )
rule    = ev.ForceRule( N, 1 )
teacher = ev.Teacher( rule, 0.2, net.time, n/2 )


@time @rec net.time net.output[1] for i in 1:n
    ev.update!(net)
    ev.learn!(net, teacher, task)
end

evl = ev.Evaluator()
print(ev.evaluate(evl, net, task, 10000))

writedlm("profile.dat", [ ev.REC[1] f(ev.REC[1]) ev.REC[2] ])

#=using PyPlot=#
#=plot(T, result)=#
#=plot(T, f(T))=#

