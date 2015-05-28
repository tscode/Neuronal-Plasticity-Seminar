
include("../src/EvoNet.jl")
ev = EvoNet
import EvoNet.@rec

# create a random network
N = 500
generator = ev.SparseMatrixGenerator( N, 0.1, gain = 1.1, feedback = 2) #2. )
# init quantities
# Function for the task
f(t) = cos(2pi*t/(20*6)) + 0.5sin(2pi*t*5/(20*6))

# a "taktgeber"
function r(t; freq=1/(20*6), amp=1, rel_width=10)
    t = t - floor(t*freq)*1/freq - 1/(2*freq)
    return amp*exp(-t.^2/freq/rel_width)
end
g(t) = 0.5r(t)

n = 10000
# The types needed for the simulation
task    = ev.FunctionTask( [f] )
net     = ev.generate( generator, 0 )
rule    = ev.ForceRule( N, 1/10 )
teacher = ev.Teacher( rule, 0.2, net.time, n/20 )


@time @rec net.time net.output[1] for i in 1:n
    ev.update!(net, [g(net.time);])
    ev.learn!(net, teacher, task)
end
#=print(net.ω_o)=#

writedlm("input_reaction.dat", [ ev.REC[1] f(ev.REC[1]) g(ev.REC[1]) ev.REC[2] ])

#=using PyPlot=#
#=plot(T, result)=#
#=plot(T, f(T))=#

